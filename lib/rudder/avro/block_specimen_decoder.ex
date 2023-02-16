defmodule Rudder.Avro.BlockSpecimenDecoder do
  use GenServer, restart: :temporary
  require Logger

  @schema_name "block-ethereum"

  @impl true
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

  def list do
    GenServer.call(__MODULE__, :list)
  end

  @impl true
  def handle_call(:list, _from, state) do
    {:reply, state, state}
  end

  @doc """
  Looks up AVRO schema stored in priv/schema using @schema name.

  Returns schema name `"com.covalenthq.brp.avro.ReplicationSegment"` if the schema exists, `:error` otherwise.
  """
  def get_schema do
    {:ok, schema} = Avrora.Storage.File.get(@schema_name)
    schema.full_name
  end

  @doc """
  Decodes `<<binary>>` using AVRO schema.

  Returns `:ok, %{decoded}` if the decoding is successful, `:error` otherwise.
  """
  def decode(binary) do
    Avrora.decode_plain(binary, schema_name: @schema_name)
  end

  @doc """
  Decodes binary file @`file_path` using AVRO schema.

  Returns `:ok, %{decoded}` if the decoding is successful, `:error` otherwise.
  """
  def decode_file(file_path) do
    {:ok, binary} = File.read(file_path)
    decode(binary)
  end

  @doc """
  Decodes all binary files @`dir_path` using AVRO schema.

  Returns `:ok, %{stream}` for lazy eval if successful, `:error` otherwise.
  """
  def decode_dir(dir_path) do
    Rudder.Util.get_file_paths(dir_path)
    |> Enum.map(fn file ->
      [file]
      |> Stream.map(&Rudder.Avro.BlockSpecimenDecoder.decode_file/1)
    end)
    |> List.flatten()
    |> Enum.sort()
  end
end
