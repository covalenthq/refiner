defmodule Refiner.PipelineTest do
  use ExUnit.Case, async: true

  test "returns the cid and hash of the processed block hash", %{} do
    # encoded specimen file: ./test-data/codec-0.38/encoded/1-22433670(codec-0.38)
    test_urls = ["ipfs://bafyreibajt5muvyuoldu3quopogb37cm6t2bdv2udrg75s5t3k5vsxuwxm"]
    expected_block_result_cid = "bafybeicenu7e7ahguyjund5lq24wvei6uhdsdc37sng5p762s56gyc3qkm"
    test_block_specimen_hash = "4512cefa823fd5f879eac94991eabf7cb9f75ac36dd35e3f5d02897eb82e58b4"
    test_bsp_key = "1_1_1_" <> test_block_specimen_hash

    expected_block_result_hash =
      <<250, 183, 180, 63, 29, 134, 184, 182, 171, 145, 225, 13, 148, 41, 225, 28, 45, 170, 1, 73,
        110, 221, 89, 227, 169, 232, 83, 115, 84, 217, 183, 182>>

    {status, cid, block_result_hash} = Refiner.Pipeline.process_specimen(test_bsp_key, test_urls)

    assert status == :ok
    assert cid == expected_block_result_cid
    assert block_result_hash == expected_block_result_hash
  end

  test "pipeline spawner starts pipeline processes", %{} do
    # encoded specimen file: ./test-data/codec-0.38/encoded/1-22434160 (codec-0.38)
    test_urls = ["ipfs://bafyreicjqck53iqchuyf6heqxgqzkihfqb6afqoruyfzqrkv6hb2ctwdye"]
    test_block_specimen_hash = "a8f265caa9f4c340aebcac6a382e0d5422097fcf0e8a0f68e52ef90609d5fedc"
    test_bsp_key = "1_1_1_" <> test_block_specimen_hash
    {:ok, task} = Refiner.Pipeline.Spawner.push_hash(test_bsp_key, test_urls, true)

    {status, cid, block_result_hash} =
      receive do
        {:result, result} -> result
        _ -> assert(false)
      after
        30_000 -> assert(false)
      end

    expected_block_result_cid = "bafybeig2bqbxhk42aznq6fap4ubbfg4zqcmdc27lb4iaymslcat56tayam"

    expected_block_result_hash =
      <<28, 194, 179, 26, 109, 156, 17, 247, 235, 26, 218, 252, 146, 109, 254, 149, 146, 8, 79,
        252, 221, 91, 204, 188, 78, 17, 60, 177, 236, 150, 45, 1>>

    assert status == :ok
    assert cid == expected_block_result_cid
    assert block_result_hash == expected_block_result_hash
  end
end
