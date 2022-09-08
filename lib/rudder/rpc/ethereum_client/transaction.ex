defmodule Rudder.RPC.EthereumClient.Transaction do
  alias Rudder.Wallet

  defstruct [
    :nonce,
    :gas_price,
    :gas_limit,
    :to,
    value: 0,
    data: <<>>,
    v: 0,
    r: <<>>,
    s: <<>>,
    chain_id: nil,
    from: nil
  ]

  def parse("0x" <> tx_rlp_hex) do
    parse(Base.decode16!(tx_rlp_hex, case: :mixed))
  end

  def parse(tx_rlp_raw) when is_binary(tx_rlp_raw) do
    [nonce, gas_price, gas_limit, to, value, data, v, r, s] = ExRLP.decode(tx_rlp_raw)

    v_num = :binary.decode_unsigned(v)

    %__MODULE__{
      nonce: :binary.decode_unsigned(nonce),
      gas_price: :binary.decode_unsigned(gas_price),
      gas_limit: :binary.decode_unsigned(gas_limit),
      to: Rudder.PublicKeyHash.parse_raw!(to),
      value: :binary.decode_unsigned(value),
      data: data,
      v: v_num,
      r: r,
      s: s,
      chain_id: compute_chain_id(v_num)
    }
  end

  def parse([nonce, gas_price, gas_limit, to, value, data]) do
    %__MODULE__{
      nonce: normalize_qty(nonce),
      gas_price: normalize_qty(gas_price),
      gas_limit: normalize_qty(gas_limit),
      to: normalize_address(to),
      value: normalize_qty(value),
      data: normalize_bin(data)
    }
  end

  def parse([nonce, gas_price, gas_limit, to, value, data, v, r, s]) do
    v_norm = normalize_qty(v)

    %__MODULE__{
      nonce: normalize_qty(nonce),
      gas_price: normalize_qty(gas_price),
      gas_limit: normalize_qty(gas_limit),
      to: normalize_address(to),
      value: normalize_qty(value),
      data: normalize_bin(data),
      v: v_norm,
      r: normalize_qty(r),
      s: normalize_qty(s),
      chain_id: compute_chain_id(v_norm)
    }
  end

  def to_rlpable(%__MODULE__{
        nonce: nonce,
        gas_price: gas_price,
        gas_limit: gas_limit,
        to: to,
        value: value,
        data: data,
        v: v,
        r: r,
        s: s
      }) do
    [nonce, gas_price, gas_limit, to, value, data, v, r, s]
    |> Enum.map(&term_to_rlpable/1)
  end

  def to_rlp(%__MODULE__{} = tx) do
    to_rlpable(tx)
    |> ExRLP.encode()
  end

  def hash(tx, with_signature?)
  def hash(%__MODULE__{v: v, r: r, s: s} = tx, true), do: hash2(tx, [v, r, s])
  def hash(%__MODULE__{chain_id: chain_id} = tx, false) when is_integer(chain_id), do: hash2(tx, [chain_id, <<>>, <<>>])
  def hash(%__MODULE__{} = tx, false), do: hash2(tx, [])

  defp hash2(
         %__MODULE__{nonce: nonce, gas_price: gas_price, gas_limit: gas_limit, to: to, value: value, data: data},
         rest
       ) do
    ([nonce, gas_price, gas_limit, to, value, data] ++ rest)
    |> Enum.map(&term_to_rlpable/1)
    |> ExRLP.encode()
    |> ExKeccak.hash_256()
  end

  def signed_by(%__MODULE__{chain_id: chain_id} = tx, %Wallet{address: sender_address, private_key: sender_privkey}) do
    msg_hash = hash(tx, false)

    {:ok, {signature, recovery}} = ExSecp256k1.sign_compact(msg_hash, sender_privkey)

    <<sig_r::256, sig_s::256>> = signature
    v_init = recovery + 27

    v_coeff =
      case chain_id do
        n when is_integer(n) and n > 0 -> n * 2 + 8
        _ -> 0
      end

    sig_v = v_init + v_coeff

    %{tx | v: sig_v, r: sig_r, s: sig_s, from: sender_address}
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
  defp term_to_rlpable(0), do: ""
  defp term_to_rlpable(%Rudder.PublicKeyHash{bytes: bin}), do: bin
  defp term_to_rlpable(data) when is_integer(data), do: :binary.encode_unsigned(data)
  defp term_to_rlpable(data) when is_binary(data), do: data

  defp compute_chain_id(nil), do: compute_chain_id(28)

  defp compute_chain_id(v) when is_integer(v) do
    case div(v - 35, 2) do
      n when n >= 0 -> n
      _ -> nil
    end
  end
end
