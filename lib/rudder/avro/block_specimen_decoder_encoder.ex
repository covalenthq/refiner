defmodule Rudder.Avro.BlockSpecimen do
  use GenServer, restart: :temporary
  require Logger

  @schema_name "block-ethereum"

  @impl true
  @spec init(any) :: {:ok, any}
  def init(state) do
    start()
    {:ok, state}
  end

  @spec start_link([
          {:debug, [:log | :statistics | :trace | {any, any}]}
          | {:hibernate_after, :infinity | non_neg_integer}
          | {:name, atom | {:global, any} | {:via, atom, any}}
          | {:spawn_opt, [:link | :monitor | {any, any}]}
          | {:timeout, :infinity | non_neg_integer}
        ]) :: :ignore | {:error, any} | {:ok, pid}
  @doc """
  Starts the block specimen decoder.
  """
  def start_link(opts) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  @spec start :: {:ok, pid}
  def start() do
    {:ok, _pid} = Avrora.start_link()
  end

  @spec list :: any
  def list do
    GenServer.call(__MODULE__, :list)
  end

  @impl true
  def handle_call(:list, _from, state) do
    {:reply, state, state}
  end

  @spec get_schema :: binary
  @doc """
  Looks up AVRO schema stored in priv/schema using @schema name.

  Returns schema name `"com.covalenthq.brp.avro.ReplicationSegment"` if the schema exists, `:error` otherwise.
  """
  def get_schema do
    {:ok, schema} = Avrora.Storage.File.get(@schema_name)
    schema.full_name
  end

  @spec decode(binary) :: {:error, any} | {:ok, map}
  @doc """
  Decodes `<<binary>>` using AVRO schema.

  Returns `:ok, %{decoded}` if the decoding is successful, `:error` otherwise.
  """
  def decode(binary) do
    Avrora.decode_plain(binary, schema_name: @schema_name)
  end

  @spec decode_file(
          binary
          | maybe_improper_list(
              binary | maybe_improper_list(any, binary | []) | char,
              binary | []
            )
        ) :: {:error, any} | {:ok, map}
  @doc """
  Decodes binary file @`file_path` using AVRO schema.

  Returns `:ok, %{decoded}` if the decoding is successful, `:error` otherwise.
  """
  def decode_file(file_path) do
    {:ok, binary} = File.read(file_path)
    decode(binary)
  end

  @spec decode_dir(
          binary
          | maybe_improper_list(
              binary | maybe_improper_list(any, binary | []) | char,
              binary | []
            )
        ) :: list
  @doc """
  Decodes all binary files @`dir_path` using AVRO schema.

  Returns `:ok, %{stream}` for lazy eval if successful, `:error` otherwise.
  """
  def decode_dir(dir_path) do
    Rudder.Util.get_file_paths(dir_path)
    |> Enum.map(fn file ->
      [file]
      |> Stream.map(&Rudder.Avro.BlockSpecimen.decode_file/1)
    end)
    |> List.flatten()
    |> Enum.sort()
  end

  @spec encode(
          binary
          | maybe_improper_list(
              binary | maybe_improper_list(any, binary | []) | byte,
              binary | []
            )
        ) :: {:error, %{:__exception__ => true, :__struct__ => atom, optional(atom) => any}}
  def encode(result_json) do
    case Poison.decode(result_json) do
      {:ok, result_map} -> Avrora.encode_plain(result_map, schema_name: @schema_name)
      err -> err
    end
  end

  @spec encode_file(
          binary
          | maybe_improper_list(
              binary | maybe_improper_list(any, binary | []) | char,
              binary | []
            )
        ) :: {:error, any} | {:ok, map}
  def encode_file(file_path) do
    {:ok, binary} = File.read(file_path)
    encode(binary)
  end

  @spec encode_dir(
          binary
          | maybe_improper_list(
              binary | maybe_improper_list(any, binary | []) | char,
              binary | []
            )
        ) :: list
  def encode_dir(dir_path) do
    Rudder.Util.get_file_paths(dir_path)
    |> Enum.map(fn file ->
      [file]
      |> Stream.map(&Rudder.Avro.BlockSpecimen.encode_file/1)
    end)
    |> List.flatten()
    |> Enum.sort()
  end
end
