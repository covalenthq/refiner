defmodule Rudder.Avro.BlockSpecimenDecoder do
  use GenServer

  @schema_name "block-ethereum"

  @impl true
  def init(state) do
    start()
    {:ok, state}
  end

  def start_link(_) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

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

  def get_schema do
    {:ok, schema} = Avrora.Storage.File.get(@schema_name)
    schema.full_name
  end

  def decode(binary) do
    Avrora.decode_plain(binary, schema_name: @schema_name)
  end

  def decode_file(file_path) do
    {:ok, binary} = File.read(file_path)
    decode(binary)
  end

  def decode_dir(dir_path) do
    Rudder.Util.file_open(dir_path)
    |> Enum.map(fn file ->
      [file]
      |> Stream.map(&Rudder.Avro.BlockSpecimenDecoder.decode_file/1)
    end)
    |> List.flatten()
    |> Enum.sort()
  end
end
