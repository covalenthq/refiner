defmodule Rudder.Pipeline do
  use GenServer

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

  defp write_to_backlog(specimen_hash, urls, _err) do
    backlog_filepath = Application.get_env(:rudder, :backlog_filepath)
    text = specimen_hash <> "," <> List.to_string(urls) <> ";"
    Rudder.Util.append_to_file(text, backlog_filepath)
  end

  def pipeline(specimen_hash, urls) do
    # try do
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

    # rescue
    #   e -> write_to_backlog(specimen_hash, urls, e)
    # end
  end
end
