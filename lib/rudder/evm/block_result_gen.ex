defmodule Rudder.BlockProcessor do
  alias Rudder.BlockProcessor
  alias Rudder.BlockProcessor.PoolSupervisor

  defmodule API do
    @doc """
    Starts a worker pool with given maximum number of workers (not enforced right now).
    """
    def start(workers_limit \\ 10) do
      PoolSupervisor.start_link(workers_limit)
    end

    @doc """
    Stops the block processor worker pool
    """
    def stop() do
      PoolSupervisor.stop()
    end

    @doc """
    Sends a synchronous request to the worker pool for manufacturing block result from the given block specimen contents
    """
    def sync_queue({block_id, contents}) do
      BlockProcessor.Server.sync_queue({block_id, contents})
    end
  end

  # useless struct for now
  defmodule PoolState do
    defstruct [:request_queue, workers_limit: 10]
  end

  defmodule PoolSupervisor do
    use Supervisor

    def start_link(workers_limit) do
      Supervisor.start_link(__MODULE__, %BlockProcessor.PoolState{workers_limit: workers_limit},
        name: :evm_poolsup
      )
    end

    @impl true
    def init(state) do
      children = [
        %{
          id: __MODULE__,
          type: :worker,
          start: {BlockProcessor.Server, :start_link, [state]},
          restart: :permanent
        }
      ]

      Supervisor.init(children, strategy: :one_for_one, max_restarts: 2, max_seconds: 20)
    end

    def get_worker_sup_spec(id, args) do
      %{
        # TODO: this ain't good!
        id: id,
        type: :supervisor,
        start: {BlockProcessor.WorkerSupervisor, :start_link, [args]},
        restart: :temporary
      }
    end

    def stop() do
      pid = Process.whereis(:evm_poolsup)

      if pid != nil and Process.alive?(pid) do
        IO.puts("stopping the pool supervisor")
        Supervisor.stop(:evm_poolsup, :normal, 50_000)
      else
        IO.puts("pool supervisor not alive...can't stop.")
      end
    end
  end

  defmodule InputParams do
    @enforce_keys [:block_id]
    defstruct [:block_id, :contents, :sender, :misc]
  end

  defmodule EVMParams do
    defstruct [:evm_exec_path, input_replica_path: "stdin", output_basedir: "./evm-out"]
  end

  defmodule ExecResult do
    defstruct [:status, :block_id, :output_path, :misc]
  end

  defmodule Server do
    use GenServer

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
      block_id_atom = String.to_atom(block_id)

      worker_sup_child_spec =
        PoolSupervisor.get_worker_sup_spec(
          block_id_atom,
          {
            %InputParams{block_id: block_id, contents: contents, sender: self(), misc: from},
            %EVMParams{evm_exec_path: "./evm/evm"}
          }
        )

      IO.puts("child spec id is #{Map.get(worker_sup_child_spec, :id)}")

      case Supervisor.start_child(:evm_poolsup, worker_sup_child_spec) do
        {:error, term} ->
          IO.puts("some error in starting stateful worker #{inspect(term)}")
          {:reply, {:submission, :failed, block_id}, state}

        _ ->
          IO.puts("#{block_id} will be processed now")
          {:noreply, state}
      end
    end

    @impl true
    def handle_info(result = %ExecResult{}, state) do
      GenServer.reply(result.misc, {result.status, result.block_id})

      child_id = String.to_atom(result.block_id)
      Supervisor.terminate_child(:evm_poolsup, child_id)
      Supervisor.delete_child(:evm_poolsup, child_id)
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

  defmodule WorkerSupervisor do
    use Supervisor

    def start_link(args) do
      IO.puts("reaches here all right")
      Supervisor.start_link(__MODULE__, args)
    end

    @impl true
    def init({inp = %InputParams{}, evm = %EVMParams{}}) do
      block_id = inp.block_id
      executor_id = block_id <> "_executor"

      children = [
        %{
          id: executor_id,
          start: {BlockProcessor.Executor, :start_link, [inp, evm]},
          type: :worker,
          restart: :transient
        }
      ]

      Supervisor.init(children, strategy: :one_for_one, max_restarts: 3, max_seconds: 10)
    end
  end

  defmodule Executor do
    def start_link(inp = %InputParams{}, evm = %EVMParams{}) do
      pid = spawn_link(__MODULE__, :execute, [inp, evm])
      {:ok, pid}
    end

    def execute(inp = %InputParams{}, evm = %EVMParams{}) do
      {handler, output_path} = process_handler(inp.block_id, evm)

      case handler do
        {:error, reason} ->
          # log self too
          IO.puts("failed: " <> reason)
          Process.exit(self(), "process spawn failed: " <> reason)

        _ ->
          :ok
      end

      Porcelain.Process.send_input(handler, inp.contents)

      case Porcelain.Process.await(handler, 60_000) do
        {:ok, result} ->
          handle_result(
            inp.sender,
            adapt_result(result.status, inp.block_id, output_path, inp.misc)
          )

        {:error, :timeout} ->
          IO.puts("log timeout here")
          raise "oops timeout"
      end

      Porcelain.Process.stop(handler)
    end

    defp adapt_result(0, block_id, output_path, misc),
      do: %ExecResult{block_id: block_id, status: :success, output_path: output_path, misc: misc}

    defp adapt_result(_, block_id, _, misc),
      do: %ExecResult{block_id: block_id, status: :failure, misc: misc}

    defp handle_result(sender, res = %ExecResult{}) do
      send(sender, res)
    end

    defp process_handler(block_id, evm = %EVMParams{}) do
      output_file = block_id <> "-result.json"
      result_path = Path.join(Path.expand(evm.output_basedir), output_file)

      {Porcelain.spawn(
         Path.expand(evm.evm_exec_path),
         [
           "t8n",
           "--input.replica",
           evm.input_replica_path,
           "--output.basedir",
           evm.output_basedir,
           "--output.blockresult",
           output_file,
           "--output.body",
           "stdout",
           "--output.alloc",
           "stdout",
           "--output.result",
           "stdout"
         ],
         in: :receive
       ), result_path}
    end
  end
end
