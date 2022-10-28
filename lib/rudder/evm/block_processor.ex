defmodule Rudder.BlockProcessor.Core do
  alias Rudder.BlockProcessor.Struct
  alias Rudder.BlockProcessor.Worker
  alias Rudder.BlockProcessor.Core

  defmodule PoolSupervisor do
    use Supervisor

    def start_link(workers_limit) do
      Supervisor.start_link(__MODULE__, %Struct.PoolState{workers_limit: workers_limit},
        name: :evm_pool_supervisor
      )
    end

    @impl true
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

    def get_worker_supervisor_childspec(id, args) do
      %{
        id: id,
        type: :supervisor,
        start: {Worker.WorkerSupervisor, :start_link, [args]},
        restart: :temporary
      }
    end

    def stop() do
      pid = Process.whereis(:evm_pool_supervisor)

      if pid != nil and Process.alive?(pid) do
        IO.puts("stopping the pool supervisor")
        Supervisor.stop(:evm_pool_supervisor, :normal, 50_000)
      else
        IO.puts("pool supervisor not alive...can't stop.")
      end
    end
  end

  defmodule Server do
    use GenServer

    @default_evm_exec_path "./plugins/evm"

    def start_link(state) do
      GenServer.start_link(__MODULE__, state, name: :evm_server)
    end

    @impl true
    def init(state) do
      {
        :ok,
        %{state | request_queue: :queue.new()}
      }
    end

    @impl true
    def handle_call({:process, block_id, contents}, from, state) do
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
            %Struct.EVMParams{evm_exec_path: @default_evm_exec_path}
          }
        )

      # IO.puts("child spec id is #{Map.get(worker_sup_child_spec, :id)}")

      case Supervisor.start_child(:evm_pool_supervisor, worker_sup_child_spec) do
        {:error, term} ->
          IO.puts("some error in starting stateful worker #{inspect(term)}")
          {:reply, {:submission, :failed, block_id}, state}

        _ ->
          IO.puts("#{block_id} will be processed now")
          {:noreply, state}
      end
    end

    @impl true
    def handle_info(result = %Struct.ExecResult{}, state) do
      GenServer.reply(result.misc, {result.status, result.output_path})

      child_id = result.block_id
      Supervisor.terminate_child(:evm_pool_supervisor, child_id)
      Supervisor.delete_child(:evm_pool_supervisor, child_id)
      {:noreply, state}
    end

    def sync_queue({block_id, contents}) do
      ## TODO: this is supposed to block the caller in case the pool is exhausted.
      GenServer.call(:evm_server, {:process, block_id, contents}, :infinity)
    end

    @impl true
    def terminate(reason, state) do
      IO.puts("oh I'm terminating #{reason}")
      IO.inspect(state)
    end
  end
end
