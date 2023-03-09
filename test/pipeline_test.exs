defmodule Rudder.PipelineTest do
  use ExUnit.Case, async: true

  test "returns the cid and hash of the processed block hash", %{} do
    # encoded specimen file: test-data/encoded/1-16791900-replica-0xcd89a7529f3bd7896ef11681bbf5f58b498d4311ec18479d7b1794101f48a767 (codec-0.32)
    test_urls = ["ipfs://bafybeidgtghegdqbrvvd7se33rfu36usbkwxpuuxd2izb4m2nnqsli5ig4"]
    expected_block_result_cid = "bafybeig7evprbyrlrah3lrv5curxny7d3k3lg2r5qgjewn3ztnfhxjcnve"
    test_block_specimen_hash = "5c25c077a028006855cfb07c998ee95ca95aedd8d9ddea2acf8b199701a8b046"
    test_bsp_key = "1_1_1_" <> test_block_specimen_hash

    expected_block_result_hash =
      <<62, 28, 236, 109, 145, 195, 228, 50, 155, 215, 35, 130, 243, 145, 124, 94, 125, 133, 173,
        134, 95, 165, 117, 150, 131, 32, 177, 11, 205, 175, 197, 87>>

    {status, cid, block_result_hash} = Rudder.Pipeline.process_specimen(test_bsp_key, test_urls)

    assert status == :ok
    assert cid == expected_block_result_cid
    assert block_result_hash == expected_block_result_hash
  end

  test "pipeline spawner starts pipeline processes", %{} do
    # encoded specimen file: test-data/encoded/1-16792500-replica-0x76d3caac45688900ed03d068188d29cb22d9acc44a3a824dc9c8de6d12c663bc (codec-0.32)
    test_urls = ["ipfs://bafybeibj4sd4emo6jqi2ugww7l5p2p4mswhn2vgi7y3uk2ba7zdtmq273a"]
    test_block_specimen_hash = "cd218d31ed5b606dae5076d01b649d849746a84735cf0f8481ad34553ee2b4b4"
    test_bsp_key = "1_1_1_" <> test_block_specimen_hash
    {:ok, agent} = Rudder.Pipeline.Spawner.push_hash(test_bsp_key, test_urls)

    expected_block_result_cid = "bafybeiftqlq4l5pgnm7wklmk7knluc4nmubylwvv5c54a5m3nbapo6piky"

    expected_block_result_hash =
      <<121, 2, 45, 96, 220, 174, 114, 170, 146, 169, 189, 44, 59, 210, 200, 130, 121, 170, 206,
        55, 63, 187, 78, 0, 56, 200, 33, 185, 247, 83, 75, 47>>

    {status, cid, block_result_hash} = Agent.get(agent, & &1)

    assert status == :ok
    assert cid == expected_block_result_cid
    assert block_result_hash == expected_block_result_hash
  end
end
