defmodule Rudder.RPC.EthereumClient.TransactionEIP1559 do
  alias Rudder.Wallet

  defstruct [
    :type,
    :nonce,
    :max_priority_fee_per_gas,
    :max_fee_per_gas,
    :to,
    :gas_limit,
    value: 0,
    data: <<>>,
    access_list: [],
    signature_y_parity: <<>>,
    signature_r: <<>>,
    signature_s: <<>>,
    chain_id: nil,
    from: nil
  ]

  def to_rlp(%__MODULE__{
        chain_id: chain_id,
        nonce: nonce,
        to: to,
        gas_limit: gas_limit,
        max_fee_per_gas: max_fee_per_gas,
        max_priority_fee_per_gas: max_priority_fee_per_gas,
        value: value,
        data: data,
        access_list: access_list,
        signature_y_parity: signature_y_parity,
        signature_r: signature_r,
        signature_s: signature_s
      }) do
    [
      chain_id,
      nonce,
      max_priority_fee_per_gas,
      max_fee_per_gas,
      gas_limit,
      to,
      value,
      data,
      access_list,
      signature_y_parity,
      signature_r,
      signature_s
    ]
    |> Enum.map(&term_to_rlpable/1)
    |> ExRLP.encode()
  end

  def unsigned_hash(%__MODULE__{
        chain_id: chain_id,
        nonce: nonce,
        gas_limit: gas_limit,
        to: to,
        max_fee_per_gas: max_fee_per_gas,
        max_priority_fee_per_gas: max_priority_fee_per_gas,
        value: value,
        data: data,
        access_list: access_list
      }) do
    rlp_encoded =
      [
        chain_id,
        nonce,
        max_priority_fee_per_gas,
        max_fee_per_gas,
        gas_limit,
        to,
        value,
        data,
        access_list
      ]
      |> Enum.map(&term_to_rlpable/1)
      |> ExRLP.encode()

    bin = :binary.encode_unsigned(0x02) <> rlp_encoded

    ExKeccak.hash_256(bin)
  end

  def signed_by(
        %__MODULE__{chain_id: chain_id} = tx,
        %Wallet{
          address: sender_address,
          private_key: sender_privkey,
          public_key: sender_pubkey
        }
      ) do
    msg_hash = unsigned_hash(tx)

    {:ok, {signature, signature_y_parity}} = ExSecp256k1.sign_compact(msg_hash, sender_privkey)

    <<sig_r::256, sig_s::256>> = signature

    %{
      tx
      | signature_y_parity: signature_y_parity,
        signature_r: sig_r,
        signature_s: sig_s,
        from: sender_address
    }
  end

  defp normalize_qty(nil), do: nil
  defp normalize_qty(n) when is_integer(n), do: n
  defp normalize_qty("0x" <> hex), do: normalize_qty(hex)

  defp normalize_qty(hex) when is_binary(hex) do
    {qty, ""} = Integer.parse(hex, 16)
    qty
  end

  defp normalize_bin(nil), do: nil
  defp normalize_bin("0x" <> hex), do: Base.decode16!(hex, case: :mixed)
  defp normalize_bin(bin) when is_binary(bin), do: bin

  def normalize_address(%Wallet{address: %Rudder.PublicKeyHash{} = pkh}), do: pkh
  def normalize_address(other), do: Rudder.PublicKeyHash.parse_raw!(normalize_bin(other))

  defp term_to_rlpable(nil), do: ""
  defp term_to_rlpable(0), do: 0
  defp term_to_rlpable(%Rudder.PublicKeyHash{bytes: bin}), do: bin
  defp term_to_rlpable(data) when is_integer(data), do: :binary.encode_unsigned(data)
  defp term_to_rlpable(data) when is_binary(data), do: data
  defp term_to_rlpable([]), do: []
end
