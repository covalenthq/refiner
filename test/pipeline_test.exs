defmodule Rudder.PipelineTest do
  use ExUnit.Case, async: true

  test "returns the cid and hash of the processed block hash", %{} do
    # encoded specimen file: test-data/encoded/1-15892728-replica-0x84a541916d6d3c974b4da961e2f00a082c03a071132f5db27787124597c094c1 (codec-0.31)
    test_urls = ["ipfs://bafybeiaar2hb22exwntqi5eurrgdql3ci2nv2udva7fhcqdkshqgo7srfi"]
    expected_block_result_cid = "bafybeihxvejooqtilcmvep6vy33ehacvt6hiyfqkq434jfbi26lo4qsi7q"

    expected_block_result_hash =
      <<105, 231, 102, 197, 138, 130, 127, 60, 117, 72, 181, 192, 13, 4, 59, 70, 74, 105, 56, 78,
        116, 108, 186, 247, 61, 119, 24, 129, 180, 220, 5, 58>>

    {status, cid, block_result_hash} =
      Rudder.Pipeline.process_specimen("1_1_wewerc323_hash", test_urls)

    assert status == :ok
    assert cid == expected_block_result_cid
    assert block_result_hash == expected_block_result_hash
  end

  test "pipeline spawner starts pipeline processes", %{} do
    # encoded specimen file: test-data/encoded/1-15892755-replica-0x0e7bfa908e3fc04003e00afde7eb31772a012e51e0e094e4add1734da92297f7 (codec-0.31)
    test_urls = ["ipfs://bafybeihg6dvzspiicrvawxy3sviwpahnryzmmsj2a4hg3sf7am55opav5u"]

    {:ok, agent} = Rudder.Pipeline.Spawner.push_hash("1_1_wewerc323_hash1", test_urls)

    expected_block_result_cid = "bafybeicwqmey3cr3gybgesjiafco3hjxxhxgze44wqsbxs4qqiuoxzluby"

    expected_block_result_hash =
      <<214, 102, 145, 182, 240, 67, 233, 253, 208, 246, 40, 113, 175, 91, 166, 104, 18, 146, 84,
        58, 250, 48, 211, 184, 35, 58, 206, 238, 33, 139, 105, 255>>

    {status, cid, block_result_hash} = Agent.get(agent, & &1)

    assert status == :ok
    assert cid == expected_block_result_cid
    assert block_result_hash == expected_block_result_hash
  end
end
