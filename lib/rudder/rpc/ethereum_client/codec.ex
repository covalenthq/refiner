defmodule Rudder.RPC.EthereumClient.Codec do
  alias Rudder.RPC.EthereumClient.Transaction

  def encode_sha256(nil), do: nil
  def encode_sha256(%Rudder.SHA256{bytes: bytes}), do: encode_sha256(bytes)
  def encode_sha256(hash) when is_binary(hash), do: encode_bin(hash)

  def encode_address(nil), do: nil

  def encode_address(n) when is_integer(n) do
    encode_bin(:binary.encode_unsigned(n))
  end

  def encode_address(
        %Rudder.PublicKeyHash{format: :ethpub, namespace: 0, bytes: bytes},
        opts \\ []
      ) do
    if Keyword.get(opts, :raw, false) do
      bytes
    else
      bin = encode_bin(bytes)

      if Keyword.get(opts, :hide_prefix, false) do
        String.trim_leading(bin, "0x")
      else
        bin
      end
    end
  end

  def encode_slot_key_path(parts) do
    slug =
      Enum.map(parts, fn
        %Rudder.SHA256{bytes: bytes} -> bytes
        %Rudder.PublicKeyHash{bytes: bytes} -> bytes
        bin when is_binary(bin) -> bin
        n when is_integer(n) -> :binary.encode_unsigned(n)
      end)
      |> Enum.map(&String.pad_leading(&1, 32, <<0>>))
      |> Enum.join("")

    mem_hash =
      case byte_size(slug) do
        0 -> <<0::256>>
        32 -> slug
        n when n > 32 -> ExKeccak.hash_256(slug)
      end

    mem_hash
    |> String.trim_leading(<<0>>)
    |> encode_bin()
  end

  def decode_address(nil), do: nil

  def decode_address("") do
    %Rudder.PublicKeyHash{format: :ethpub, namespace: 0, bytes: <<0::160>>}
  end

  def decode_address(bytes) when byte_size(bytes) == 20 do
    %Rudder.PublicKeyHash{format: :ethpub, namespace: 0, bytes: bytes}
  end

  def decode_address(<<"0x", _::binary>> = bin) do
    decode_bin(bin)
    |> decode_address
  end

  def decode_address(<<"one", _::binary>> = bech32) do
    {:ok, {"one", bytes}} = Bech32.decode(bech32)
    decode_address(bytes)
  end

  def encode_default_block(:latest), do: "latest"
  def encode_default_block(:earliest), do: "earliest"
  def encode_default_block(:pending), do: "pending"
  def encode_default_block(qty), do: encode_qty(qty)

  def encode_transaction(%Transaction{} = tx) do
    Transaction.to_rlp(tx)
    |> encode_bin()
  end

  def encode_call_transaction(call_tx) do
    call_tx
    |> Keyword.delete(:decode)
    |> Enum.into(%{}, fn
      {:from, addr} -> {"from", encode_address(addr)}
      {:to, addr} -> {"to", encode_address(addr)}
      {:gas, qty} -> {"gas", encode_qty(qty)}
      {:gas_price, qty} -> {"gasPrice", encode_qty(qty)}
      {:value, qty} -> {"value", encode_qty(qty)}
      {:data, payload_parts} -> {"data", encode_call_payload(payload_parts)}
    end)
  end

  def encode_hl_call_payload(selector, params) do
    params_bins =
      normalize_hl_call_payload_part(params)
      |> List.wrap()

    ABI.TypeEncoder.encode(params_bins, selector)
    |> encode_bin()
  end

  defp normalize_hl_call_payload_part(l) when is_list(l),
    do: Enum.map(l, &normalize_hl_call_payload_part/1)

  defp normalize_hl_call_payload_part({}), do: {}

  defp normalize_hl_call_payload_part({a}),
    do: {normalize_hl_call_payload_part(a)}

  defp normalize_hl_call_payload_part({a, b}),
    do: {normalize_hl_call_payload_part(a), normalize_hl_call_payload_part(b)}

  defp normalize_hl_call_payload_part({a, b, c}) do
    {
      normalize_hl_call_payload_part(a),
      normalize_hl_call_payload_part(b),
      normalize_hl_call_payload_part(c)
    }
  end

  defp normalize_hl_call_payload_part(t) when is_tuple(t) and tuple_size(t) > 3 do
    Tuple.to_list(t)
    |> Enum.map(&normalize_hl_call_payload_part/1)
    |> List.to_tuple()
  end

  defp normalize_hl_call_payload_part(%Rudder.SHA256{bytes: bytes}), do: bytes
  defp normalize_hl_call_payload_part(%Rudder.PublicKeyHash{bytes: bytes}), do: bytes
  defp normalize_hl_call_payload_part(other), do: other

  def encode_call_payload({selector, params}) do
    ABI.encode_call_payload(selector, params)
    |> encode_call_payload()
  end

  def encode_call_payload(bin) when is_binary(bin) do
    encode_bin(bin)
  end

  def decode_call_result(bin, call_tx) do
    {selector, _} = call_tx[:data]
    selector = decode_selector(selector)

    case {Keyword.get(call_tx, :decode, true), selector.returns, decode_bin(bin)} do
      {false, _, returned_data} ->
        returned_data

      {true, nil, _} ->
        nil

      {true, _, ""} ->
        nil

      {true, {:tuple, _} = return_type, returned_data} ->
        [decoded_data] =
          ABI.TypeDecoder.decode_raw(returned_data, [return_type], discard_rest: true)

        decoded_data

      {true, return_type, returned_data} ->
        decoded_data = ABI.decode_output(selector, returned_data)

        decoded_data
    end
  end

  def decode_multicall_result(%ABI.FunctionSelector{returns: sel_rt}, results_by_contract) do
    with {:ok, sel_rt_fixed} <- normalize_selector_return_type(sel_rt) do
      Map.new(results_by_contract, fn {contract_addr_enc, results_bins} ->
        contract_addr = decode_address(contract_addr_enc)

        results =
          Enum.map(results_bins, fn
            %{"Error" => err_str} ->
              {:error, err_str}

            %{"Err" => err_str} ->
              {:error, err_str}

            %{"ReturnData" => result_bin} ->
              result =
                decode_bin(result_bin)
                |> ABI.TypeDecoder.decode_raw(sel_rt_fixed, discard_rest: true)
                |> unwrap_selector_return_tuple()

              {:ok, result}

            _ ->
              {:error, :no_data}
          end)

        {contract_addr, results}
      end)
    end
  end

  def normalize_selector_return_type(""), do: nil
  def normalize_selector_return_type({:tuple, _} = t), do: {:ok, [t]}
  def normalize_selector_return_type(t), do: {:ok, [{:tuple, [t]}]}

  defp unwrap_selector_return_tuple([t]) when is_tuple(t), do: Tuple.to_list(t)

  def decode_selector(%ABI.FunctionSelector{} = s), do: s
  def decode_selector(str), do: ABI.FunctionSelector.decode(str)

  def encode_qty(nil), do: nil

  def encode_qty(n) when is_integer(n) do
    "0x" <> String.downcase(Integer.to_string(n, 16))
  end

  def encode_bin(bin) when is_binary(bin) do
    "0x" <> Base.encode16(bin, case: :lower)
  end

  def decode_block(block, discovered_on_network \\ nil)

  def decode_block(nil, _), do: nil

  def decode_block(block, discovered_on_network) when is_map(block) do
    {transaction_ids, transactions} =
      case Enum.map(block["transactions"], &decode_transaction/1) do
        [] -> {[], []}
        [%Rudder.SHA256{} | _] = txids -> {txids, nil}
        txs -> {nil, txs}
      end

    mining_cost =
      if discovered_on_network.ingest_mining_costs(),
        do: decode_qty(block["difficulty"])

    block = [
      discovered_on_network: discovered_on_network,
      hash: decode_sha256(block["hash"]),
      signed_at: decode_timestamp(block["timestamp"]),
      namespace: 0,
      parent_hash: decode_sha256(block["parentHash"]),
      height: decode_qty(block["number"]),
      uncles: decode_uncles(block["uncles"]),
      extra_data: decode_bin(block["extraData"]),
      miner: decode_address(block["miner"]),
      mining_cost: mining_cost,
      gas_limit: decode_qty(block["gasLimit"]),
      gas_used: decode_qty(block["gasUsed"]),
      transaction_ids: transaction_ids,
      transactions: transactions,
      networks: []
    ]

    without_nils(block)
  end

  def extract_signed_at_from_raw_block(block) when is_map(block) do
    with {:ok, qty} <- Map.fetch(block, "timestamp"),
         unix_ts <- decode_qty(qty) do
      DateTime.from_unix(unix_ts)
    end
  end

  def extract_signed_at_from_raw_block(nil), do: :error

  def decode_seal_fields(nonce, seal_fields) do
    fields =
      case {seal_fields, nonce} do
        {nil, nil} -> []
        {l, nil} when is_list(l) -> l
        {nil, n} when is_binary(n) -> [n]
        {l, n} when is_list(l) and is_binary(n) -> l
      end

    fields
    |> Enum.map(&decode_bin/1)
    |> Enum.sort_by(&byte_size/1)
  end

  def decode_uncles(uncles) when is_list(uncles),
    do: Enum.map(uncles, &decode_sha256/1)

  def decode_uncles(nil), do: nil

  def decode_transactions(txs) when is_list(txs),
    do: Enum.map(txs, &decode_transaction/1)

  def decode_transaction(transaction_id) when is_binary(transaction_id) do
    decode_sha256(transaction_id)
  end

  def decode_transaction(tx) when is_map(tx) do
    without_nils(
      hash: decode_sha256(tx["hash"]),
      tx_offset: decode_qty(tx["transactionIndex"]) || 0,
      namespace: 0,
      from: decode_address(tx["from"]),
      to: decode_address(tx["to"]),
      creates: decode_address(tx["creates"]),
      value: decode_qty(tx["value"]),
      contract_input: decode_evm_argdata(tx["input"]),
      gas_offered: decode_qty(tx["gas"]),
      gas_price: decode_qty(tx["gasPrice"])
    )
  end

  def decode_transaction_receipts(receipts) when is_list(receipts),
    do: Enum.map(receipts, &decode_transaction_receipt/1)

  def decode_transaction_receipt(receipt) when is_map(receipt) do
    without_nils(
      successful: decode_boolean_qty(receipt["status"]),
      creates: decode_address(receipt["contractAddress"]),
      log_events: Enum.map(receipt["logs"], &decode_log/1),
      gas_spent: decode_qty(receipt["gasUsed"]),
      fees_paid: decode_fees_paid(get_in(receipt, ["feeStats", "paid"]))
    )
  end

  def decode_log(log) when is_map(log) do
    without_nils(
      log_offset: decode_qty(log["logIndex"]) || 0,
      removed: log["removed"],
      tx_offset: decode_qty(log["transactionIndex"]),
      sender: decode_address(log["address"]),
      topics: decode_log_topics(log["topics"]),
      data: decode_evm_argdata(log["data"])
    )
  end

  def decode_log_topics(nil), do: []
  def decode_log_topics([]), do: []

  def decode_log_topics(topics) when is_list(topics),
    do: Enum.map(topics, &decode_log_topic/1)

  def decode_log_topic(bin) do
    decode_bin(bin)
    |> Rudder.SHA256.new()
  end

  def extract_address_from_log_topic(%Rudder.SHA256{bytes: <<0::96, addr::binary-size(20)>>}),
    do: %Rudder.PublicKeyHash{format: :ethpub, namespace: 0, bytes: addr}

  def linearize_log_offsets(logs) do
    Enum.sort_by(logs, fn log ->
      {Map.get(log, :log_offset), Map.get(log, :tx_offset)}
    end)
    |> Enum.reduce([], &linearize_log_offsets/2)
    |> Enum.reverse()
  end

  def linearize_log_offsets(log, []), do: [log]

  def linearize_log_offsets(%{log_offset: a} = e, [%{log_offset: b} | _] = acc) when a <= b,
    do: [%{e | log_offset: b + 1} | acc]

  def linearize_log_offsets(e, acc), do: [e | acc]

  def decode_fees_paid(nil), do: nil

  def decode_fees_paid(fees) when is_map(fees) do
    Map.values(fees)
    |> Enum.map(&decode_qty/1)
    |> Enum.sum()
  end

  def decode_sha256(nil), do: nil

  def decode_sha256(bin) do
    case decode_bin(bin) do
      <<0::256>> -> nil
      bytes -> Rudder.SHA256.new(bytes)
    end
  end

  def decode_timestamp(nil), do: nil
  def decode_timestamp(qty), do: DateTime.from_unix!(decode_qty(qty))

  def decode_sync_status(false), do: false

  def decode_sync_status(status) when is_map(status) do
    Enum.into(status, %{}, fn
      {"blockGap", qty_list} -> {:block_gap, Enum.map(qty_list, &decode_qty/1)}
      {k, v} -> {decode_map_key(k), decode_qty(v)}
    end)
  end

  def decode_map_key(key) do
    String.to_atom(Macro.underscore(key))
  end

  def decode_evm_argdata(hex_data) do
    case decode_bin(hex_data) do
      "" -> nil
      bin_data -> bin_data
    end
  end

  def decode_evm_bytecode(""), do: {nil, []}
  def decode_evm_bytecode("0x" <> hex_with_externs), do: decode_evm_bytecode(hex_with_externs)

  def decode_evm_bytecode(hex_with_externs) when is_binary(hex_with_externs) do
    {_, parts, externs} =
      Regex.scan(~r/_+[^_]+?_+|[0-9a-f]+/, hex_with_externs)
      |> Enum.reduce({0, [], []}, fn [part], {pos, parts, externs} ->
        case part do
          bin when byte_size(bin) == 40 ->
            case Base.decode16(bin, case: :lower) do
              {:ok, bcode_bin} ->
                {pos + byte_size(bcode_bin), [bcode_bin | parts], externs}

              :error ->
                symbol = String.trim(bin, "_")
                {pos + 20, [<<0::160>> | parts], [{symbol, pos} | externs]}
            end

          hex when is_binary(hex) ->
            bcode_bin = Base.decode16!(hex, case: :lower)
            {pos + byte_size(bcode_bin), [bcode_bin | parts], externs}
        end
      end)

    cleaned_bytecode_bin =
      Enum.reverse(parts)
      |> :erlang.iolist_to_binary()

    externs = Enum.reverse(externs)

    {cleaned_bytecode_bin, externs}
  end

  def decode_boolean_qty(nil), do: nil

  def decode_boolean_qty(qty) when is_binary(qty) do
    decode_qty(qty) == 1
  end

  def decode_qty(nil), do: nil
  def decode_qty("0x" <> hex), do: decode_qty(hex)
  def decode_qty(""), do: 0
  def decode_qty(n) when is_integer(n), do: n

  def decode_qty(hex) do
    {qty, ""} = Integer.parse(hex, 16)
    qty
  end

  def decode_addr_balance(nil), do: nil

  def decode_addr_balance(%{} = addr_balance_map) do
    Map.new(addr_balance_map, fn {addr, balance} ->
      {decode_address(addr), decode_qty(balance)}
    end)
  end

  def decode_bin(nil), do: nil
  def decode_bin("0x" <> hex), do: decode_bin(hex)
  def decode_bin(""), do: ""
  def decode_bin(hex), do: Base.decode16!(hex, case: :mixed)

  defp without_nils(kw) do
    Enum.filter(kw, fn
      {_, nil} -> false
      _pair -> true
    end)
    |> Map.new()
  end
end
