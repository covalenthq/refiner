defmodule Rudder.Pipeline do
  defmodule Spawner do
    use DynamicSupervisor

    def start_link(_) do
      DynamicSupervisor.start_link(__MODULE__, [], name: __MODULE__, strategy: :one_for_one)
    end

    @impl true
    def init(_) do
      DynamicSupervisor.init(strategy: :one_for_one)
    end

    def push_hash(specimen_hash, urls) do
      DynamicSupervisor.start_child(
        __MODULE__,
        {Agent,
         fn ->
           Rudder.Pipeline.process_specimen(specimen_hash, urls)
         end}
      )
    end
  end

  def process_specimen(specimen_hash, urls) do
    try do
      with {:ok, specimen} <- Rudder.IPFSInteractor.discover_block_specimen(urls),
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
    rescue
      e -> write_to_backlog(specimen_hash, urls, e)
    end
  end

  defp convert_block_hash_read(data) do
    # this is a temp solution until prod agents' codec schema is updated
    converted_block_hash_read =
      Enum.map(data["State"]["BlockhashRead"], fn el ->
        truncated = trunc(el["BlockNumber"])
        Map.replace(el, "BlockNumber", truncated)
      end)

    state = data["State"]
    state = Map.replace(state, "BlockhashRead", converted_block_hash_read)
    data = Map.replace(data, "State", state)
    {:ok, data}
  end

  defp extract_block_specimen_metadata(decoded_specimen) do
    with {:ok, block_height} <- Map.fetch(decoded_specimen, "startBlock"),
         {:ok, replica_event} <- fetch_replica_event(decoded_specimen),
         {:ok, data} <- Map.fetch(replica_event, "data"),
         {:ok, data} <- convert_block_hash_read(data),
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

  defp fetch_replica_event(decoded_specimen) do
    with {:ok, replica_event} <- Map.fetch(decoded_specimen, "replicaEvent") do
      [replica_event | _] = replica_event
      {:ok, replica_event}
    else
      err -> err
    end
  end

  defp write_to_backlog(specimen_hash, urls, err) do
    IO.inspect(err)
    # backlog_filepath = Application.get_env(:rudder, :backlog_filepath)
    # text = specimen_hash <> "," <> List.to_string(urls) <> ";"
    # Rudder.Util.append_to_file(text, backlog_filepath)
  end
end
