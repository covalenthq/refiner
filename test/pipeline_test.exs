defmodule Refiner.PipelineTest do
  use ExUnit.Case, async: true

  test "returns the cid and hash of the processed block hash", %{} do
    # encoded specimen file: test-data/codec-0.36/encoded/1-19434485-replica-0x5800aab40ca1c9aedae3329ad82ad051099edaa293d68504b987a12acfa7b799 (codec-0.36)
    test_urls = ["ipfs://bafybeich2doxzqmls5hrrdb4v4fibxqjqnhcvguamp5lmvyg45h2gz5xkm"]
    expected_block_result_cid = "bafybeieexakgvuk5mg7zxyat7skwc27siabcfgksofp6ovhzu7j5inkq5y"
    test_block_specimen_hash = "3cf79c299079befbbf7852364921455e75d6b73cef1b559f6791fd0490160836"
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
    # encoded specimen file: test-data/codec-0.36/encoded/1-19434555-replica-0x3e6af5a88c6205e03364e4a8e4d6d558d53bbea0ed9398df0ee078e6bce3086e (codec-0.36)
    test_urls = ["ipfs://bafybeihfjhxfr3r2ti7phs7gzwbx5oimzf6ainhccrk2hlzoozcmcsu36q"]
    test_block_specimen_hash = "e8da96c1936beca082677f0a634f659970f1646b3a6ca2d555f038aeb076e006"
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
