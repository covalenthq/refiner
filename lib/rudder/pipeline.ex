defmodule Rudder.Pipeline do
  use GenServer

  @impl true
  def init(_) do
    {:ok, []}
  end

  def start_link(_) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  # TODOs:
  # - keep track of duplicate specimens
  # - keep track of fail backlog
  # - implement file clean up
  # - fix block processor
  # - set up ProofChain for testing
  # - add tests
  def pipeline(specimen_hash, urls) do
    # urls = ["ipfs://QmR4BQi8fTdZM28GuWmtfjkbNPPzxiHCBNRXJng6rSEfcv"]
    {:ok, specimen} = Rudder.BlockSpecimenDiscoverer.discover_block_specimen(urls)
    {:ok, decoded_specimen} = Rudder.Avro.BlockSpecimenDecoder.decode(specimen)
    {:ok, block_height} = Map.fetch(decoded_specimen, "startBlock")
    block_height = Integer.to_string(block_height)
    {:ok, replica_event} = Map.fetch(decoded_specimen, "replicaEvent")
    [specimen | _] = replica_event
    {:ok, data} = Map.fetch(specimen, "data")
    {:ok, chain_id} = Map.fetch(data, "NetworkId")
    specimen = Poison.encode!(data)
    {:success, block_result_file_path} = Rudder.BlockProcessor.sync_queue({"block_id", specimen})

    # Rudder.Pipeline.pipeline("a", [])

    block_result_metadata = %Rudder.BlockResultMetadata{
      chain_id: chain_id,
      block_height: 1,
      block_specimen_hash: specimen_hash,
      file_path: block_result_file_path
    }

    IO.inspect(block_result_metadata)

    {:ok, cid, block_result_hash} =
      Rudder.BlockResultUploader.upload_block_result(block_result_metadata)

    IO.inspect(cid)
    IO.inspect(block_result_hash)

    :ok = File.rm(block_result_file_path)
    {:ok, cid, block_result_hash}
  end
end
