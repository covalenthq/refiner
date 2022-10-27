defmodule Rudder.Preprocessor do
  use GenServer

  @impl true
  def init(_) do
    {:ok, []}
  end

  def start_link(_) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def preprocess(specimen_hash) do
    #1
    specimen_contents = Rudder.SourceDiscovery.get_specimen(specimen_hash)
    #2
    {:ok, decoded_specimen} = Rudder.Avro.BlockSpecimenDecoder.decode(specimen_contents)

    {:ok, decoded_specimen_start_block} = Map.fetch(decoded_specimen, "startBlock")
    block_id = decoded_specimen_start_block
    contents = decoded_specimen

    #3
    result = GenServer.cast(Rudder.BlockProcessor.Core.Server, {:process, block_id, contents})
    # fail up if this fails
    # or log, put it in backlog


    #4 push to IPFS and ProofChain
    # {:ok, block_id, contents}

    #5 clean up - block result
    

    # change in a block no evm tool updated fails ->
  end

  @impl true
  def handle_cast({:preprocess, specimen_hash}, state) do
    pipeline(specimen_hash)
    {:noreply, [state]}
  end
end
