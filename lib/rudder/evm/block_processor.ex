defmodule Rudder.BlockProcessor.Core do
  require Logger
  alias Rudder.BlockProcessor.Struct
  alias Rudder.BlockProcessor.Worker
  alias Rudder.BlockProcessor.Core
  alias Rudder.Events

  defmodule PoolSupervisor do
    use Supervisor

    @spec start_link(any) :: :ignore | {:error, any} | {:ok, pid}
    def start_link(workers_limit) do
      Supervisor.start_link(__MODULE__, %Struct.PoolState{workers_limit: workers_limit},
        name: :evm_pool_supervisor
      )
    end

    @impl true
    @spec init(any) :: {:ok, {%{intensity: any, period: any, strategy: any}, list}}
    def init(state) do
      children = [
        %{
          id: __MODULE__,
          type: :worker,
          start: {Core.Server, :start_link, [state]},
          restart: :permanent
        }
      ]

      # the worker supervisor fails on 3 restarts in 10 seconds...so if there are two of them in 20 seconds,
      # the PoolSupervisor fails indicating some problem with the setup
      Supervisor.init(children, strategy: :one_for_one, max_restarts: 2, max_seconds: 20)
    end

    @spec get_worker_supervisor_childspec(any, any) :: %{
            id: any,
            restart: :temporary,
            start: {Rudder.BlockProcessor.Worker.WorkerSupervisor, :start_link, [...]},
            type: :supervisor
          }
    def get_worker_supervisor_childspec(id, args) do
      %{
        id: id,
        type: :supervisor,
        start: {Worker.WorkerSupervisor, :start_link, [args]},
        restart: :temporary
      }
    end

    @spec stop :: :ok
    def stop() do
      pid = Process.whereis(:evm_pool_supervisor)

      if pid != nil and Process.alive?(pid) do
        Logger.info("stopping the pool supervisor")
        Supervisor.stop(:evm_pool_supervisor, :normal, 50_000)
      else
        Logger.warn("pool supervisor not alive...can't stop.")
      end
    end
  end

  defmodule Server do
    use GenServer

    @spec start_link(any) :: :ignore | {:error, any} | {:ok, pid}
    def start_link(state) do
      GenServer.start_link(__MODULE__, state, name: :evm_server)
    end

    @impl true
    @spec init(any) :: {:ok, any}
    def init(state) do
      {
        :ok,
        state
      }
    end

    @impl true
    def handle_call(
          {:process, %Rudder.BlockSpecimen{block_height: block_id, contents: contents}},
          from,
          state
        ) do
      Logger.info("submitting #{block_id} to evm plugin...")
      start_execute_ms = System.monotonic_time(:millisecond)

      worker_sup_child_spec =
        PoolSupervisor.get_worker_supervisor_childspec(
          block_id,
          {
            %Struct.InputParams{
              block_id: block_id,
              contents: contents,
              sender: self(),
              misc: from
            },
            Struct.EVMParams.new()
          }
        )

      case Supervisor.start_child(:evm_pool_supervisor, worker_sup_child_spec) do
        {:error, term} ->
          Logger.error("some error in starting stateful worker #{inspect(term)}")
          {:reply, {:submission, :failed, block_id}, state}

        _ ->
          Logger.info("#{block_id} will be processed now")
          Events.evm_execute(System.monotonic_time(:millisecond) - start_execute_ms)
          {:noreply, state}
      end
    end

    @impl true
    def handle_info(%Struct.ExecResult{} = result, state) do
      GenServer.reply(result.misc, {result.status, result.output_path})

      child_id = result.block_id
      Supervisor.terminate_child(:evm_pool_supervisor, child_id)
      Supervisor.delete_child(:evm_pool_supervisor, child_id)
      {:noreply, state}
    end

    def sync_queue(%Rudder.BlockSpecimen{} = block_specimen, _state) do
      GenServer.call(:evm_server, {:process, block_specimen}, :infinity)
    end

    @impl true
    def terminate(reason, _state) do
      Logger.info("terminating #{reason}")
    end
  end
end
