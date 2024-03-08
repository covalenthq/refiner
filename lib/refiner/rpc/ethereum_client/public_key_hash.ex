defmodule Refiner.RPC.PublicKeyHash do
  defstruct format: :p2pkh,
            namespace: 0,
            chain_id: nil,
            bytes: <<0::160>>

  alias Refiner.RPC.EthereumClient.Codec, as: EthereumCodec

  @codecs_by_format %{
    ethpub: EthereumCodec
  }

  @zero_address EthereumCodec.decode_address("0x0000000000000000000000000000000000000000")

  @spec zero_address :: %Refiner.RPC.PublicKeyHash{
          bytes: <<_::160>>,
          chain_id: nil,
          format: :ethpub,
          namespace: 0
        }
  def zero_address(), do: @zero_address

  def sigil_a(bin, []), do: parse!(bin)

  def parse(%__MODULE__{} = pkh), do: {:ok, pkh}

  def parse(bin) when is_binary(bin) and byte_size(bin) == 20 do
    {:ok, EthereumCodec.decode_address(bin)}
  end

  def parse(<<"0x", _::bytes-size(40)>> = hex) do
    {:ok, EthereumCodec.decode_address(hex)}
  end

  def parse(_), do: :error

  def parse!(v) do
    {:ok, pkh} = parse(v)
    pkh
  end

  @spec parse_raw(any) ::
          :error
          | {:ok,
             nil
             | %Refiner.RPC.PublicKeyHash{
                 bytes: bitstring,
                 chain_id: nil,
                 format: :ethpub,
                 namespace: 0
               }}
  def parse_raw(bin) when is_binary(bin) and byte_size(bin) == 20 do
    {:ok, EthereumCodec.decode_address(bin)}
  end

  def parse_raw(_), do: :error

  @spec parse_raw!(any) ::
          nil
          | %Refiner.RPC.PublicKeyHash{
              bytes: bitstring,
              chain_id: nil,
              format: :ethpub,
              namespace: 0
            }
  def parse_raw!(v) do
    {:ok, pkh} = parse_raw(v)
    pkh
  end

  @spec new(any, any, any, any) :: %Refiner.RPC.PublicKeyHash{
          bytes: any,
          chain_id: any,
          format: any,
          namespace: any
        }
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

  @spec type :: :binary
  @doc false
  def type, do: :binary

  @doc false
  def cast(v), do: parse(v)

  @spec load(any) ::
          :error
          | {:ok,
             nil
             | %Refiner.RPC.PublicKeyHash{
                 bytes: bitstring,
                 chain_id: nil,
                 format: :ethpub,
                 namespace: 0
               }}
  @doc false
  def load(bin), do: parse_raw(bin)

  @spec dump(any) :: :error | {:ok, any}
  @doc false
  def dump(%__MODULE__{} = pkh), do: as_external(pkh)
  def dump(_), do: :error

  @spec equal?(any, any) :: boolean
  @doc false
  def equal?(a, b), do: a == b
end

defimpl Jason.Encoder, for: Refiner.RPC.PublicKeyHash do
  @spec encode(%Refiner.RPC.PublicKeyHash{}, Jason.Encode.opts()) :: [
          binary | maybe_improper_list(any, binary | []) | byte,
          ...
        ]
  def encode(%Refiner.RPC.PublicKeyHash{} = pkh, opts) do
    Refiner.RPC.PublicKeyHash.as_string!(pkh)
    |> Jason.Encode.string(opts)
  end
end

defimpl String.Chars, for: Refiner.RPC.PublicKeyHash do
  @spec to_string(%Refiner.RPC.PublicKeyHash{}) :: any
  def to_string(pkh), do: Refiner.RPC.PublicKeyHash.as_string!(pkh)
end

defimpl Inspect, for: Refiner.RPC.PublicKeyHash do
  import Inspect.Algebra

  @spec inspect(%Refiner.RPC.PublicKeyHash{}, Inspect.Opts.t()) ::
          :doc_line
          | :doc_nil
          | binary
          | {:doc_collapse, pos_integer}
          | {:doc_force, any}
          | {:doc_break | :doc_color | :doc_cons | :doc_fits | :doc_group | :doc_string, any, any}
          | {:doc_nest, any, :cursor | :reset | non_neg_integer, :always | :break}
  def inspect(
        %Refiner.RPC.PublicKeyHash{format: format, namespace: namespace, chain_id: chain_id} =
          pkh,
        opts
      ) do
    {:ok, str_repr} = Refiner.RPC.PublicKeyHash.as_string(pkh, hide_prefix: true)

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
