Code.require_file("helpers.exs", "test/evm/helpers")

defmodule SupervisionTreeTest do
  use ExUnit.Case, async: false
  @moduletag :spawn
  require Logger
  alias Rudder.BlockProcessor.Worker.Executor
  alias Rudder.BlockProcessor.Struct

  alias TestHelper.EVMInputGenerator
  alias TestHelper.SupervisorUtils

  # sync_queue success: successful execution from a stateful worker -> status code = 0, workers executed once, response back to the api, WorkerSupervisor is cleared
  # sync_queue success (wrong json structure): same as above, except status code != 0, and no retries of the worker (executed once)
  # sync_queue failures: failure reason: evm executable not present -- test return value, retries of the worker, check if relevant processes are there, poolsupervisor should be closed

  # multiple queueing - pool supervisors should be configured by a worker pool size (maximum # of simultaneous workers), and anything above that should block
  # registry for worker name

  test "successful scenarios - status code 0 execution" do
    block_id = "1234_s_"

    contents = get_sample_specimen!()

    inp = %Struct.InputParams{block_id: block_id, contents: contents, sender: self()}
    evm = Struct.EVMParams.new()

    _ =
      SupervisorUtils.start_link_supervised!(%{
        id: "sample",
        start: {Executor, :start_link, [inp, evm]},
        type: :worker,
        restart: :transient
      })

    receive do
      %Struct.ExecResult{
        block_id: ^block_id,
        status: status,
        output_path: _,
        misc: nil
      } ->
        ExUnit.Assertions.assert(status == :success, "status is not success")

      msg ->
        Logger.info("unhandled message: #{inspect(msg)}")
        ExUnit.Assertions.assert(false, "unhandled message")
    after
      3000 ->
        ExUnit.Assertions.assert(false, "didn't receive status within timeout interval")
    end
  end

  test "status code !=0 execution (json cannot be unmarshalled into evm structure)" do
    block_id = "1234_f_"

    contents = get_sample_specimen!()

    inp = %Struct.InputParams{
      block_id: block_id,
      contents: "[" <> contents <> "]",
      sender: self()
    }

    evm = Struct.EVMParams.new()

    _ =
      TestHelper.SupervisorUtils.start_link_supervised!(%{
        id: "sample",
        start: {Executor, :start_link, [inp, evm]},
        type: :worker,
        restart: :transient
      })

    receive do
      %Struct.ExecResult{
        block_id: ^block_id,
        status: status,
        output_path: _,
        misc: nil
      } ->
        ExUnit.Assertions.assert(status != :success, "status is unexpectedly success")

      msg ->
        Logger.info("unhandled message: #{inspect(msg)}")
        ExUnit.Assertions.assert(false, "unhandled message")
    after
      3000 ->
        ExUnit.Assertions.assert(false, "didn't receive status within timeout interval")
    end
  end

  test "evm executable not present" do
    block_id = "1234_f_"
    contents = get_sample_specimen!()

    inp = %Struct.InputParams{block_id: block_id, contents: contents, sender: self()}
    evm = %Struct.EVMParams{evm_exec_path: "./blahblahrandomness/evm"}

    Process.flag(:trap_exit, true)

    _ =
      SupervisorUtils.start_link_supervised!(%{
        id: "sample",
        start: {Executor, :start_link, [inp, evm]},
        type: :worker,
        restart: :transient
      })

    assert_receive({:EXIT, _, _}, 3_000)
  end

  def get_sample_specimen!() do
    path = Path.join([__DIR__, "data", "15548376-segment.json"])
    File.read!(path)
  end
end
