defmodule Rudder.Preprocessor do
  use GenServer

  @impl true
  def init(_) do
    {:ok, []}
  end

  def start_link(_) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def pipeline(specimen_hash) do
    
    specimen_file_path = Rudder.SourceDiscovery.get_specimen_file_path(specimen_hash)
    {:ok, decoded_specimen} = Rudder.Avro.BlockSpecimenDecoder.decode_file(specimen_file_path)

    {:ok, decoded_specimen_start_block} = Map.fetch(decoded_specimen, "startBlock")
    # noreply????
    handle_call({:process, block_id, contents}, from, state)


    # pull data from ipfs using the given specimen hash and push the result for further processing?
    IO.inspect("Source Discovery received the specimen hash: " <> specimen_hash)
    IO.inspect("")
  end

  @impl true
  def handle_cast({:push, specimen_hash}, state) do
    pipeline(specimen_hash)
    {:noreply, [state]}
  end
end
