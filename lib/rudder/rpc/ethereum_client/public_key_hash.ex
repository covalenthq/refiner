defmodule Rudder.PublicKeyHash do
  defstruct format: :p2pkh,
            namespace: 0,
            chain_id: nil,
            bytes: <<0::160>>

  alias Rudder.RPC.EthereumClient.Codec, as: EthereumCodec

  @codecs_by_format %{
    ethpub: EthereumCodec
  }

  @zero_address EthereumCodec.decode_address("0x0000000000000000000000000000000000000000")

  def zero_address(), do: @zero_address

  def sigil_a(bin, []), do: parse!(bin)

  def parse(%__MODULE__{} = pkh), do: {:ok, pkh}

  def parse(bin) when is_binary(bin) and byte_size(bin) == 20 do
    {:ok, EthereumCodec.decode_address(bin)}
  end

  def parse(<<"0x", _::bytes-size(40)>> = hex) do
    {:ok, EthereumCodec.decode_address(hex)}
  end

  def parse(bin) when is_binary(bin) and byte_size(bin) == 21 do
    {:ok, BitcoinCodec.decode_address(bin)}
  end

  def parse(b58c) when is_binary(b58c) and byte_size(b58c) >= 26 and byte_size(b58c) <= 53 do
    {:ok, BitcoinCodec.decode_address(b58c)}
  end

  def parse(_), do: :error

  def parse!(v) do
    {:ok, pkh} = parse(v)
    pkh
  end

  def parse_raw(bin) when is_binary(bin) and byte_size(bin) == 20 do
    {:ok, EthereumCodec.decode_address(bin)}
  end

  def parse_raw(bin) when is_binary(bin) and byte_size(bin) == 21 do
    {:ok, BitcoinCodec.decode_address(bin)}
  end

  def parse_raw(_), do: :error

  def parse_raw!(v) do
    {:ok, pkh} = parse_raw(v)
    pkh
  end

  def new(format, namespace, chain_id, bytes) do
    %__MODULE__{format: format, namespace: namespace, chain_id: chain_id, bytes: bytes}
  end

  def as_external(%__MODULE__{format: format} = pkh) do
    with {:ok, codec} <- Map.fetch(@codecs_by_format, format) do
      {:ok, codec.encode_address(pkh, raw: true)}
    end
  end

  def as_external!(%__MODULE__{} = pkh) do
    {:ok, bin} = as_external(pkh)
    bin
  end

  def as_string(%__MODULE__{format: format} = pkh, opts \\ []) do
    with {:ok, codec} <- Map.fetch(@codecs_by_format, format) do
      {:ok, codec.encode_address(pkh, opts)}
    end
  end

  def as_string!(%__MODULE__{} = pkh, opts \\ []) do
    {:ok, str} = as_string(pkh, opts)
    str
  end

  @doc false
  def type, do: :binary

  @doc false
  def cast(v), do: parse(v)

  @doc false
  def load(bin), do: parse_raw(bin)

  @doc false
  def dump(%__MODULE__{} = pkh), do: as_external(pkh)
  def dump(_), do: :error

  @doc false
  def equal?(a, b), do: a == b
end

defimpl Jason.Encoder, for: Rudder.PublicKeyHash do
  def encode(%Rudder.PublicKeyHash{} = pkh, opts) do
    Rudder.PublicKeyHash.as_string!(pkh)
    |> Jason.Encode.string(opts)
  end
end

defimpl String.Chars, for: Rudder.PublicKeyHash do
  def to_string(pkh), do: Rudder.PublicKeyHash.as_string!(pkh)
end

defimpl Inspect, for: Rudder.PublicKeyHash do
  import Inspect.Algebra

  def inspect(
        %Rudder.PublicKeyHash{format: format, namespace: namespace, chain_id: chain_id} = pkh,
        opts
      ) do
    {:ok, str_repr} = Rudder.PublicKeyHash.as_string(pkh, hide_prefix: true)

    str_repr_doc = str_repr_doc(str_repr, opts)

    prefix_part = color(to_string(format), :atom, opts)

    prefix_part =
      case chain_id do
        nil ->
          prefix_part

        cid ->
          concat([
            prefix_part,
            color("/", :tuple, opts),
            color(to_string(cid), :string, opts)
          ])
      end

    prefix_part =
      case namespace do
        nil -> prefix_part
        0 -> prefix_part
        nsp -> space(prefix_part, color(to_string(nsp), :atom, opts))
      end

    concat([
      color("(", :tuple, opts),
      space(
        prefix_part,
        str_repr_doc
      ),
      color(")", :tuple, opts)
    ])
  end

  if Mix.env() == :prod do
    defp str_repr_doc(str_repr, opts) do
      str_repr_first = String.slice(str_repr, 0, 7)
      str_repr_last = String.slice(str_repr, -10, 10)

      concat([
        color(str_repr_first, :number, opts),
        color("...", :tuple, opts),
        color(str_repr_last, :number, opts)
      ])
    end
  else
    defp str_repr_doc(str_repr, opts) do
      color(str_repr, :number, opts)
    end
  end
end
