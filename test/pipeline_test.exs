defmodule Refiner.PipelineTest do
  use ExUnit.Case, async: true

  test "returns the cid and hash of the processed block hash", %{} do
    # encoded specimen file: test-data/codec-0.35/encoded/1-17090940-replica-0x7b8e1d463a0fbc6fce05b31c5c30e605aa13efaca14a1f3ba991d33ea979b12b (codec-0.35)
    test_urls = ["ipfs://bafybeig46j3nmrbpmrgkdwhi4h3ajmudnehhrh6uwzbrdpk72hjjtj6uou"]
    expected_block_result_cid = "bafybeieexakgvuk5mg7zxyat7skwc27siabcfgksofp6ovhzu7j5inkq5y"
    test_block_specimen_hash = "54245042c6cc9a9d80888db816525d097984c3c2ba4f11d64e9cdf6aaefe5e8d"
    test_bsp_key = "1_1_1_" <> test_block_specimen_hash

    expected_block_result_hash =
      <<105, 50, 175, 90, 71, 36, 11, 89, 40, 141, 86, 97, 77, 37, 70, 218, 93, 72, 45, 15, 41,
        190, 77, 26, 60, 229, 65, 201, 154, 114, 47, 253>>

    {status, cid, block_result_hash} = Refiner.Pipeline.process_specimen(test_bsp_key, test_urls)

    assert status == :ok
    assert cid == expected_block_result_cid
    assert block_result_hash == expected_block_result_hash
  end

  test "pipeline spawner starts pipeline processes", %{} do
    # encoded specimen file: test-data/codec-0.35/encoded/1-17090960-replica-0xc95d44182ee006e79f1352ef32664210f383baa016988d5ab2fd950b52bf22ff (codec-0.35)
    test_urls = ["ipfs://bafybeihfjhxfr3r2ti7phs7gzwbx5oimzf6ainhccrk2hlzoozcmcsu36q"]
    test_block_specimen_hash = "6a1a24cfbee3d64c7f6c7fd478ec0e1112176d1340f18d0ba933352c6ce2026a"
    test_bsp_key = "1_1_1_" <> test_block_specimen_hash
    {:ok, task} = Refiner.Pipeline.Spawner.push_hash(test_bsp_key, test_urls, true)

    {status, cid, block_result_hash} =
      receive do
        {:result, result} -> result
        _ -> assert(false)
      after
        30_000 -> assert(false)
      end

    expected_block_result_cid = "bafybeifkk56vhaiqwfijernkd3blthcavol6dmwgcfm2g3op6wmw3obiy4"

    expected_block_result_hash =
      <<125, 209, 148, 90, 204, 95, 113, 187, 206, 110, 137, 86, 41, 90, 1, 140, 224, 3, 206, 72,
        126, 126, 247, 116, 234, 15, 9, 93, 220, 190, 153, 210>>

    assert status == :ok
    assert cid == expected_block_result_cid
    assert block_result_hash == expected_block_result_hash
  end
end
