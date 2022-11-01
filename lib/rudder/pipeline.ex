defmodule Rudder.Pipeline do
  use GenServer

  # defmodule Supervisor do
  #   use Supervisor

  #   @backlog_filepath ""

  #   def start_link(workers_limit) do
  #     Supervisor.start_link(__MODULE__, [], name: :pipeline_supervisor)
  #   end

  #   @impl true
  #   def init(state) do
  #     children = [
  #       %{
  #         id: __MODULE__,
  #         type: :worker,
  #         start: {Core.Server, :start_link, [state]},
  #         restart: :permanent
  #       }
  #     ]

  #     # the worker supervisor fails on 3 restarts in 10 seconds...so if there are two of them in 20 seconds,
  #     # the PoolSupervisor fails indicating some problem with the setup
  #     Supervisor.init(children, strategy: :one_for_one, max_restarts: 2, max_seconds: 20)
  #   end

  #   def on_fail(specimen) do
  #     append_to_file(text, filepath)
  #   end

  # end

  @impl true
  def init(_) do
    {:ok, []}
  end

  def start_link(_) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  defp fetch_replica_event(decoded_specimen) do
    with {:ok, replica_event} <- Map.fetch(decoded_specimen, "replicaEvent") do
      [replica_event | _] = replica_event
      {:ok, replica_event}
    else
      err -> err
    end
  end

  defp extract_block_specimen_metadata(decoded_specimen) do
    with {:ok, block_height} <- Map.fetch(decoded_specimen, "startBlock"),
         {:ok, replica_event} <- fetch_replica_event(decoded_specimen),
         {:ok, data} <- Map.fetch(replica_event, "data"),
         {:ok, chain_id} <- Map.fetch(data, "NetworkId") do
      {:ok,
       %Rudder.BlockSpecimenMetadata{
         chain_id: chain_id,
         block_height: Integer.to_string(block_height),
         contents: Poison.encode!(data)
       }}
    else
      err -> err
    end
  end

  defp write_to_backlog(specimen_hash, urls, err) do
    :ok
  end

  # TODOs:
  # - keep track of duplicate specimens
  # - keep track of fail backlog
  # - set up ProofChain for testing
  # - add tests
  def pipeline(specimen_hash, urls) do
    # urls = ["ipfs://QmR4BQi8fTdZM28GuWmtfjkbNPPzxiHCBNRXJng6rSEfcv"]
    with {:ok, specimen} <- Rudder.BlockSpecimenDiscoverer.discover_block_specimen(urls),
         {:ok, decoded_specimen} <- Rudder.Avro.BlockSpecimenDecoder.decode(specimen),
         {:ok, block_specimen_metadata} <- extract_block_specimen_metadata(decoded_specimen),
         {:success, block_result_file_path} <-
           Rudder.BlockProcessor.sync_queue(block_specimen_metadata),
         block_result_metadata <- %Rudder.BlockResultMetadata{
           chain_id: block_specimen_metadata.chain_id,
           block_height: block_specimen_metadata.block_height,
           block_specimen_hash: specimen_hash,
           file_path: block_result_file_path
         },
         {:ok, cid, block_result_hash} <-
           Rudder.BlockResultUploader.upload_block_result(block_result_metadata),
         :ok <- File.rm(block_result_file_path) do
      {:ok, cid, block_result_hash}
    else
      err -> write_to_backlog(specimen_hash, urls, err)
    end
  end
end
