Code.require_file("helpers.exs", "test/evm/helpers")

defmodule SupervisionTreeTest do
  use ExUnit.Case, async: false
  @moduletag :spawn
  require Logger
  alias Refiner.BlockProcessor.Struct

  alias TestHelper.EVMInputGenerator
  alias TestHelper.SupervisorUtils

  test "successful scenarios - status code 0 execution" do
    block_id = "1234_s_"

    contents = get_sample_specimen!()

    {:ok, filepath} = Refiner.BlockProcessor.sync_queue(contents)
    File.rm(filepath)
  end

  test "status code !=0 execution (json cannot be unmarshalled into evm structure)" do
    block_id = "1234_f_"

    specimen = get_sample_specimen!()

    {:error, errormsg} =
      Refiner.BlockProcessor.sync_queue(%Refiner.BlockSpecimen{
        chain_id: specimen.chain_id,
        block_height: specimen.block_height,
        contents: "[" <> specimen.contents <> "]"
      })
  end

  # test "query-ing server at wrong port" do
  #   block_id = "1234_f_"

  #   specimen = get_sample_specimen!()
  #   {:ok, bpid} = Refiner.BlockProcessor.start_link(["http://127.0.0.1:3100"])
  #   {:error, errormsg} = GenServer.call(bpid, {:process, "dfjkejkjfd"}, 60_000)
  # end

  test "handles block processor server error" do
    block_id = "1234_f_"

    specimen = get_sample_specimen!()

    {:ok, bpid} =
      Refiner.BlockProcessor.start_link([Application.get_env(:refiner, :evm_server_url)])

    {:error, error_msg} = GenServer.call(bpid, {:process, "invalid content"}, 60_000)

    assert error_msg ==
             "ERROR(10): error unmarshalling replica file: invalid character 'i' looking for beginning of value"
  end

  def get_sample_specimen!() do
    path = Path.join([__DIR__, "data", "15548376-segment.json"])

    %Refiner.BlockSpecimen{
      chain_id: 1,
      block_height: 15_548_376,
      contents: File.read!(path)
    }
  end
end
