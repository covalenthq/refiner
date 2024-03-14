defmodule Refiner.PipelineTest do
  use ExUnit.Case, async: true

  test "returns the cid and hash of the processed block hash", %{} do
    # encoded specimen file: test-data/codec-0.36/encoded/1-19434485-replica-0x5800aab40ca1c9aedae3329ad82ad051099edaa293d68504b987a12acfa7b799 (codec-0.36)
    test_urls = ["ipfs://bafybeich2doxzqmls5hrrdb4v4fibxqjqnhcvguamp5lmvyg45h2gz5xkm"]
    expected_block_result_cid = "bafybeib3xkzaxuldyiyadngetbd622wmj4zegwcnd4pl4unslqurxa4xi4"
    test_block_specimen_hash = "3cf79c299079befbbf7852364921455e75d6b73cef1b559f6791fd0490160836"
    test_bsp_key = "1_1_1_" <> test_block_specimen_hash

    expected_block_result_hash =
      <<75, 182, 220, 247, 103, 1, 28, 138, 198, 79, 120, 116, 0, 120, 220, 176, 217, 166, 128,
        117, 26, 7, 3, 9, 87, 65, 143, 138, 182, 197, 214, 25>>

    {status, cid, block_result_hash} = Refiner.Pipeline.process_specimen(test_bsp_key, test_urls)

    assert status == :ok
    assert cid == expected_block_result_cid
    assert block_result_hash == expected_block_result_hash
  end

  test "pipeline spawner starts pipeline processes", %{} do
    # encoded specimen file: test-data/codec-0.36/encoded/1-19434555-replica-0x3e6af5a88c6205e03364e4a8e4d6d558d53bbea0ed9398df0ee078e6bce3086e (codec-0.36)
    test_urls = ["ipfs://bafybeiaroqslztoplmyyaduz2kfhfmqdeybkfx7sojbisj2rsoryvmmu3y"]
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

    expected_block_result_cid = "bafybeicpsrm3h5g6st6k2vi5awwu55wzdtvgmailpod2e53leexsk2ptcy"

    expected_block_result_hash =
      <<48, 29, 244, 136, 156, 152, 111, 196, 64, 170, 248, 64, 226, 153, 56, 140, 31, 209, 169,
        224, 185, 27, 214, 237, 245, 92, 137, 197, 127, 183, 104, 187>>

    assert status == :ok
    assert cid == expected_block_result_cid
    assert block_result_hash == expected_block_result_hash
  end
end
