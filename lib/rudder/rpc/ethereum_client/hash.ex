defmodule Rudder.SHA256 do
  defstruct [:bytes]

  def sigil_h(maybe_pfx_hexhash, []), do: parse(maybe_pfx_hexhash)

  def parse("0x" <> bin), do: new(bin)
  def parse(other), do: new(other)

  def new(%__MODULE__{} = h), do: h

  def new(hexhash) when is_binary(hexhash) and byte_size(hexhash) == 64 do
    %__MODULE__{bytes: Base.decode16!(hexhash, case: :mixed)}
  end

  def new(raw_hash)
      when is_binary(raw_hash) and (byte_size(raw_hash) == 32 or byte_size(raw_hash) == 88) do
    %__MODULE__{bytes: raw_hash}
  end

  def as_string(%__MODULE__{bytes: bytes}) do
    Base.encode16(bytes, case: :lower)
  end

  @spec type :: :binary
  @doc false
  def type, do: :binary

  @spec equal?(any, any) :: boolean
  @doc false
  def equal?(a, b), do: a == b

  @doc false
  def cast(hexhash) when is_binary(hexhash) and byte_size(hexhash) == 64 do
    {:ok, new(hexhash)}
  end

  def cast(%__MODULE__{} = h), do: {:ok, h}
  def cast(_), do: :error

  @spec load(any) :: :error | {:ok, %Rudder.SHA256{bytes: binary}}
  @doc false
  def load(data) when is_binary(data) and byte_size(data) == 32 do
    {:ok, %__MODULE__{bytes: data}}
  end

  def load(_), do: :error

  @spec dump(any) :: :error | {:ok, any}
  @doc false
  def dump(%__MODULE__{bytes: data}), do: {:ok, data}
  def dump(_), do: :error
end

defimpl Jason.Encoder, for: Rudder.SHA256 do
  def encode(%Rudder.SHA256{} = hash, opts) do
    Rudder.SHA256.as_string(hash)
    |> Jason.Encode.string(opts)
  end
end

defimpl String.Chars, for: Rudder.SHA256 do
  def to_string(block_hash), do: Rudder.SHA256.as_string(block_hash)
end

defimpl Inspect, for: Rudder.SHA256 do
  import Inspect.Algebra

  case Mix.env() do
    :prod ->
      def inspect(%Rudder.SHA256{bytes: hash}, opts) do
        hash_hex = Base.encode16(hash, case: :lower)
        hash_start = String.slice(hash_hex, 0..1)
        hash_end = String.slice(hash_hex, 52..63)

        concat(["♯", hash_start, "...", hash_end])
        |> color(:string, opts)
      end

    _ ->
      @spec inspect(%Rudder.SHA256{}, Inspect.Opts.t()) ::
              :doc_line
              | :doc_nil
              | binary
              | {:doc_collapse, pos_integer}
              | {:doc_force, any}
              | {:doc_break | :doc_color | :doc_cons | :doc_fits | :doc_group | :doc_string, any,
                 any}
              | {:doc_nest, any, :cursor | :reset | non_neg_integer, :always | :break}
      def inspect(%Rudder.SHA256{bytes: hash}, opts) do
        hash_hex = Base.encode16(hash, case: :lower)

        concat(["♯", hash_hex])
        |> color(:string, opts)
      end
  end
end
