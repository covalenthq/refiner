defmodule Rudder.BlockResultUploader do
  require Logger
  alias Rudder.Events
  use GenServer

  @spec start_link([
          {:debug, [:log | :statistics | :trace | {any, any}]}
          | {:hibernate_after, :infinity | non_neg_integer}
          | {:name, atom | {:global, any} | {:via, atom, any}}
          | {:spawn_opt, [:link | :monitor | {any, any}]}
          | {:timeout, :infinity | non_neg_integer}
        ]) :: :ignore | {:error, any} | {:ok, pid}
  def start_link(opts) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  @impl true
  @spec init(:ok) :: {:ok, []}
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
    start_upload_ms = System.monotonic_time(:millisecond)

    case Rudder.IPFSInteractor.pin(file_path) do
      {:ok, cid} ->
        specimen_hash_bytes32 = Rudder.Util.convert_to_bytes32(block_specimen_hash)

        Logger.info(
          "#{block_height}:#{block_specimen_hash} has been successfully uploaded at ipfs://#{cid}"
        )

        block_result_hash = hash_block_result_file(file_path)

        Logger.info("#{block_height}:#{block_specimen_hash} proof submitting")

        case Rudder.ProofChain.Interactor.submit_block_result_proof(
               chain_id,
               block_height,
               specimen_hash_bytes32,
               block_result_hash,
               cid
             ) do
          {:ok, :submitted} ->
            :ok = Events.brp_upload_success(System.monotonic_time(:millisecond) - start_upload_ms)
            {:reply, {:ok, cid, block_result_hash}, state}

          {:error, errormsg} ->
            Logger.error(
              "#{block_height}:#{block_specimen_hash} proof submission error: #{errormsg}"
            )

            :ok = Events.brp_upload_failure(System.monotonic_time(:millisecond) - start_upload_ms)
            {:reply, {:error, errormsg, ""}, state}

          {:error, :irreparable, errormsg} ->
            :ok = Events.brp_upload_failure(System.monotonic_time(:millisecond) - start_upload_ms)
            {:reply, {:error, :irreparable, errormsg}, state}
        end

      {:error, error} ->
        {:reply, {:error, error, ""}, state}
    end
  end

  @spec upload_block_result(any) :: any
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
