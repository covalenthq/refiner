defmodule Refiner.Pipeline do
  alias Refiner.Events
  require Logger
  alias Refiner.Util.GVA
  require GVA
  use Task

  defmodule ProofSubmissionIrreparableError do
    defexception message: "default message"
  end

  defmodule Spawner do
    use DynamicSupervisor

    @spec start_link(any) :: none
    def start_link(_) do
      DynamicSupervisor.start_link(__MODULE__, [], name: __MODULE__, strategy: :one_for_one)
    end

    @impl true
    @spec init(any) ::
            {:ok,
             %{
               extra_arguments: list,
               intensity: non_neg_integer,
               max_children: :infinity | non_neg_integer,
               period: pos_integer,
               strategy: :one_for_one
             }}
    def init(_) do
      DynamicSupervisor.init(strategy: :one_for_one)
    end

    @spec push_hash(any, any) :: :ignore | {:error, any} | {:ok, pid} | {:ok, pid, any}
    def push_hash(bsp_key, urls, reply \\ false) do
      caller_pid = self()

      DynamicSupervisor.start_child(
        __MODULE__,
        {Task,
         fn ->
           return_val = Refiner.Pipeline.process_specimen(bsp_key, urls)

           if reply do
             send(caller_pid, {:result, return_val})
           end
         end}
      )
    end
  end

  @spec process_specimen(any, any) :: any
  def process_specimen(bsp_key, urls) do
    start_pipeline_ms = System.monotonic_time(:millisecond)
    is_prev_uploader_state_ok = is_uploader_status_ok()

    try do
      with [_chain_id, _block_height, _block_hash, specimen_hash] <- String.split(bsp_key, "_"),
           {:ok, specimen} <- Refiner.IPFSInteractor.discover_block_specimen(urls),
           {:ok, decoded_specimen} <- Refiner.Avro.BlockSpecimen.decode(specimen),
           {:ok, block_specimen} <- extract_block_specimen(decoded_specimen),
           {:ok, block_result_file_path} <-
             Refiner.BlockProcessor.sync_queue(block_specimen),
           {block_height, ""} <- Integer.parse(block_specimen.block_height),
           block_result_metadata <-
             %Refiner.BlockResultMetadata{
               chain_id: block_specimen.chain_id,
               block_height: block_height,
               block_specimen_hash: specimen_hash,
               file_path: block_result_file_path
             } do
        return_val =
          case Refiner.BlockResultUploader.upload_block_result(block_result_metadata) do
            {:ok, cid, block_result_hash} ->
              :ok = Refiner.Journal.commit(bsp_key)
              rec_uploader_success()

              if !is_prev_uploader_state_ok && is_uploader_status_ok() do
                # upload pipeline is succeeding again, retry the older failed bsps
                set_retry_failed_bsp()
              end

              Events.refiner_pipeline_success(
                System.monotonic_time(:millisecond) - start_pipeline_ms
              )

              {:ok, cid, block_result_hash}

            {:error, :irreparable, errormsg} ->
              rec_uploader_failure()

              Events.refiner_pipeline_failure(
                System.monotonic_time(:millisecond) - start_pipeline_ms
              )

              raise(Refiner.Pipeline.ProofSubmissionIrreparableError, errormsg)

            {:error, error, _block_result_hash} ->
              rec_uploader_failure()

              Logger.info(
                "#{block_height} has error on upload/proof submission: #{inspect(error)}"
              )

              log_error_info(bsp_key, urls, error)

              Events.refiner_pipeline_failure(
                System.monotonic_time(:millisecond) - start_pipeline_ms
              )

              {:error, error}
          end

        return_val
      else
        err ->
          log_error_info(bsp_key, urls, err)
          rec_uploader_failure()
      end
    after
      # resource cleanups
      Briefly.cleanup()
    rescue
      e in Refiner.Pipeline.ProofSubmissionIrreparableError ->
        log_error_info(bsp_key, urls, e)
        Logger.error(Exception.format(:error, e, __STACKTRACE__))
        Process.exit(Process.whereis(:bspec_listener), :irreparable)

      e ->
        log_error_info(bsp_key, urls, e)
    end
  end

  defp extract_block_specimen(decoded_specimen) do
    start_decode_ms = System.monotonic_time(:millisecond)

    with {:ok, block_height} <- Map.fetch(decoded_specimen, "startBlock"),
         {:ok, replica_event} <- fetch_replica_event(decoded_specimen),
         {:ok, data} <- Map.fetch(replica_event, "data"),
         {:ok, chain_id} <- Map.fetch(data, "NetworkId") do
      :ok = Events.bsp_decode(System.monotonic_time(:millisecond) - start_decode_ms)

      {:ok,
       %Refiner.BlockSpecimen{
         chain_id: chain_id,
         block_height: Integer.to_string(block_height),
         contents: Poison.encode!(data)
       }}
    else
      err -> err
    end
  end

  defp fetch_replica_event(decoded_specimen) do
    case Map.fetch(decoded_specimen, "replicaEvent") do
      {:ok, replica_event} ->
        [replica_event | _] = replica_event
        {:ok, replica_event}

      err ->
        err
    end
  end

  defp log_error_info(bsp_key, urls, err) do
    # logging key and url, so that it can be retried from local elixir shell
    Logger.warn("key #{bsp_key} written to backlog with #{urls}; error: #{inspect(err)}")
  end

  defp init_state() do
    GVA.gnew(:state)
    GVA.gput(:state, :retry_failed_bsp, false)
    GVA.gput(:state, :uploader_status, :ok)
  end

  def set_retry_failed_bsp() do
    if !GVA.gexists(:state) do
      init_state()
    end

    GVA.gput(:state, :retry_failed_bsp, true)
  end

  def clear_retry_failed_bsp() do
    if !GVA.gexists(:state) do
      init_state()
    end

    GVA.gput(:state, :retry_failed_bsp, false)
  end

  def is_retry_failed_bsp() do
    if !GVA.gexists(:state) do
      init_state()
    end

    GVA.gget(:state, :retry_failed_bsp)
  end

  def is_uploader_status_ok() do
    if !GVA.gexists(:state) do
      init_state()
    end

    :ok == GVA.gget(:state, :uploader_status)
  end

  def rec_uploader_success() do
    if !GVA.gexists(:state) do
      init_state()
    end

    GVA.gput(:state, :uploader_status, :ok)
  end

  def rec_uploader_failure() do
    if !GVA.gexists(:state) do
      init_state()
    end

    GVA.gput(:state, :uploader_status, :err)
  end
end
