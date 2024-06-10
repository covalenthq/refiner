defmodule Refiner.PipelineTest do
  use ExUnit.Case, async: true

  test "returns the cid and hash of the processed block hash", %{} do
    # encoded specimen file: ./test-data/codec-0.37/segments/1-20063085 (codec-0.37)
    test_urls = ["ipfs://bafybeidpfxf7czfkeaiszdciyvaeahnqhop6flcssqf6s4udb7jolgciky"]
    expected_block_result_cid = "bafybeib3xkzaxuldyiyadngetbd622wmj4zegwcnd4pl4unslqurxa4xi4"
    test_block_specimen_hash = "0cfa8133a57504678b9003e1f6827ef5f394e41678a5336b6d4b6de4230596d9"
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
    # encoded specimen file: ./test-data/codec-0.37/segments/1-20063050 (codec-0.37)
    test_urls = ["ipfs://bafybeiegf53afgfamjfjips6gf4onap3ljayokjvmfux4uqmgmkxcig2ea"]
    test_block_specimen_hash = "1a5c54be289b40e9f1b041393a02e3ff7dd37d963038904e3bcd04ad6135221e"
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
