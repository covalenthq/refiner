Code.require_file("helpers.exs", "test/evm/helpers")

defmodule SupervisionTreeTest do
  use ExUnit.Case, async: false
  @moduletag :spawn
  require Logger
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

    {:ok, filepath} = Rudder.BlockProcessor.sync_queue(contents)
    File.rm(filepath)
  end

  test "status code !=0 execution (json cannot be unmarshalled into evm structure)" do
    block_id = "1234_f_"

    specimen = get_sample_specimen!()

    {:error, errormsg} =
      Rudder.BlockProcessor.sync_queue(%Rudder.BlockSpecimen{
        chain_id: specimen.chain_id,
        block_height: specimen.block_height,
        contents: "[" <> specimen.contents <> "]"
      })
  end

  def get_sample_specimen!() do
    path = Path.join([__DIR__, "data", "15548376-segment.json"])

    %Rudder.BlockSpecimen{
      chain_id: 1,
      block_height: 15_548_376,
      contents: File.read!(path)
    }
  end
end
