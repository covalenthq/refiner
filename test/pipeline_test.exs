defmodule Rudder.PipelineTest do
  use ExUnit.Case, async: true

  test "returns the cid and hash of the processed block hash", %{} do
    test_urls = ["ipfs://QmR4BQi8fTdZM28GuWmtfjkbNPPzxiHCBNRXJng6rSEfcv"]
    expected_cid = "bafkreiawcv77lmfzm4wl2tmhtxx6zgkjo6eabxufjhulnbc4zk7pbg7ciy"

    expected_block_result_hash =
      <<22, 21, 127, 245, 176, 185, 103, 44, 189, 77, 135, 157, 239, 236, 153, 73, 119, 136, 0,
        222, 133, 73, 232, 182, 132, 92, 202, 190, 240, 155, 226, 70>>

    {status, cid, block_result_hash} = Rudder.Pipeline.process_specimen("hash", test_urls)
    assert status == :ok
    assert cid == expected_cid
    assert block_result_hash == expected_block_result_hash
  end

  # test "pipeline spawner starts pipeline processes", %{} do
  #   test_urls = ["ipfs://QmUmd2Eme1ZNnJ8nSSmhtwnTeNdwW39YMszBug4oKnaBZM"]
  #   {:ok, agent} = Rudder.Pipeline.Spawner.push_hash("hash1", test_urls)

  #   # expected_cid = "bafkreiawcv77lmfzm4wl2tmhtxx6zgkjo6eabxufjhulnbc4zk7pbg7ciy"

  #   # expected_block_result_hash =
  #   #   <<22, 21, 127, 245, 176, 185, 103, 44, 189, 77, 135, 157, 239, 236, 153, 73, 119, 136, 0,
  #   #     222, 133, 73, 232, 182, 132, 92, 202, 190, 240, 155, 226, 70>>

  #   # {status, cid, block_result_hash} = Agent.get(agent, & &1)
  #   IO.inspect(Agent.get(agent, & &1))

  #   # assert status == :ok
  #   # assert cid == expected_cid
  #   # assert block_result_hash == expected_block_result_hash
  # end

  # test "pipeline spawner writes to backlog with invalid urls", %{} do
  #   test_urls = ["ipfs://QmR4BQi8fTdZM28GuWmtfjkbNPPzxiHCBNRXJng6rSEfcv"]
  #   r = Rudder.Pipeline.Spawner.push_hash("hash1", [])
  #   IO.inspect(r)
  #   # IO.inspect(Agent.get(agent2, & &1))
  #   # # => %{}
  #   IO.inspect(DynamicSupervisor.count_children(Rudder.Pipeline.Spawner))
  #   #     {status, cid, block_result_hash} = Rudder.Pipeline.pipeline("hash", [])
  # end

  # test "generates a specimen backlog file with the failed specimen hash", %{} do
  #   {status, cid, block_result_hash} = Rudder.Pipeline.pipeline("hash", [])
  # end
end
