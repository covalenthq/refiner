Code.require_file("helpers.exs", "test/evm/helpers")

defmodule SupervisionTreeTest do
  use ExUnit.Case, async: false
  @moduletag :spawn
  require Logger
  alias Rudder.BlockProcessor.Struct

  alias TestHelper.EVMInputGenerator
  alias TestHelper.SupervisorUtils

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

  test "query-ing server at wrong port" do
    block_id = "1234_f_"

    specimen = get_sample_specimen!()
    {:ok, bpid} = Rudder.BlockProcessor.start_link(["http://127.0.0.1:3100"])
    {:error, errormsg} = GenServer.call(bpid, {:process, "dfjkejkjfd"}, 60000)
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
