defmodule Rudder.BlockResultUploader do
  require Logger
  use GenServer

  def start_link(opts) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  @impl true
  def init(:ok) do
    {:ok, []}
  end

  @impl true
  def handle_call(
        {:upload_block_result,
         %Rudder.BlockResultMetadata{
           chain_id: chain_id,
           block_height: block_height,
           block_specimen_hash: block_specimen_hash,
           file_path: file_path
         }},
        _from,
        state
      ) do
    case Rudder.IPFSInteractor.pin(file_path) do
      {:ok, cid} ->
        specimen_hash_bytes32 = Rudder.Util.convert_to_bytes32(block_specimen_hash)
        Logger.info("#{block_height}:#{block_specimen_hash} successfully uploaded ")
        block_result_hash = hash_block_result_file(file_path)

        :ok =
          Rudder.ProofChain.Interactor.submit_block_result_proof(
            chain_id,
            block_height,
            specimen_hash_bytes32,
            block_result_hash,
            cid
          )

        Logger.info("#{block_height}:#{block_specimen_hash} proof submitted")

        {:reply, {:ok, cid, block_result_hash}, state}

      {:error, error} ->
        {:reply, {:error, error, ""}, state}
    end
  end

  def upload_block_result(block_result_metadata) do
    GenServer.call(
      Rudder.BlockResultUploader,
      {:upload_block_result, block_result_metadata},
      :infinity
    )
  end

  defp hash_block_result_file(file_path) do
    hash_ref = :crypto.hash_init(:sha256)

    File.stream!(file_path)
    |> Enum.reduce(hash_ref, fn chunk, prev_ref ->
      new_ref = :crypto.hash_update(prev_ref, chunk)
      new_ref
    end)
    |> :crypto.hash_final()
  end
end
