defmodule Rudder.Pipeline do
  use GenServer

  @impl true
  def init(_) do
    {:ok, []}
  end

  def start_link(_) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  defp delete_block_result(file_path) do
    :ok
  end

  # TODOs:
  # - keep track of duplicate specimens
  # - keep track of fail backlog
  # - implement file clean up
  # - fix block processor
  # - set up ProofChain for testing
  # - add tests
  def pipeline(specimen_hash, _urls) do
    urls = ["ipfs://QmR4BQi8fTdZM28GuWmtfjkbNPPzxiHCBNRXJng6rSEfcv"]
    {:ok, specimen} = Rudder.BlockSpecimenDiscoverer.discover_block_specimen(urls)
    {:ok, decoded_specimen} = Rudder.Avro.BlockSpecimenDecoder.decode(specimen)
    {:ok, block_id} = Map.fetch(decoded_specimen, "startBlock")
    result = Rudder.BlockProcessor.sync_queue({block_id, decoded_specimen})
    # IO.inspect(result)
    # {status, _block_id, block_result_file_path} = result

    # block_result_metadata = %Rudder.BlockResultMetadata{
    #   chain_id: 1,
    #   block_height: 2,
    #   block_specimen_hash: specimen_hash,
    #   file_path: block_result_file_path
    # }

    # {:ok, cid, block_result_hash} =
    #   Rudder.BlockResultUploader.upload_block_result(block_result_metadata)

    # :ok = delete_block_result(block_result_file_path)
  end
end
