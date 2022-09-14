defmodule Rudder.Avro.DecodeBlockSpecimen do
  use GenServer

  @impl true
  def init(_) do
    start()
    {:ok, []}
  end

  @schema_name "block-ethereum"
  @file_path "./bin/block-specimen/"

  def start_link(_) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def start() do
    block_specimen = <<>>
    decode_block_specimen_binary(block_specimen)
  end

  defp get_avro_schema do
    {:ok, schema} = Avrora.Storage.File.get(@schema_name)
  end

  defp decode_block_specimen_binary(file) do
    {:ok, pid} = Avrora.start_link()

    {:ok, files} = File.ls(@file_path)

    # {:ok, schema} = Avrora.Storage.File.get(@schema_name)

    {:ok, decoded} = Avrora.decode(files, schema_name: @schema_name)
  end

  def stream_block_specimen_files do
    File.ls(@file_path)
    |> Enum.map(fn file ->
      file
      |> File.stream!()
      |> Stream.map(&String.strip/1)
    end)
    |> List.flatten()
    |> Enum.sort()
  end
end
