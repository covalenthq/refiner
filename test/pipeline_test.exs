defmodule Refiner.PipelineTest do
  use ExUnit.Case, async: true

  test "returns the cid and hash of the processed block hash", %{} do
    # encoded specimen file: ./test-data/codec-0.37/encoded/1-20063085 (codec-0.37)
    test_urls = ["ipfs://bafybeidpfxf7czfkeaiszdciyvaeahnqhop6flcssqf6s4udb7jolgciky"]
    expected_block_result_cid = "bafybeicenu7e7ahguyjund5lq24wvei6uhdsdc37sng5p762s56gyc3qkm"
    test_block_specimen_hash = "0cfa8133a57504678b9003e1f6827ef5f394e41678a5336b6d4b6de4230596d9"
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
    # encoded specimen file: ./test-data/codec-0.37/encoded/1-20063050 (codec-0.37)
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

    expected_block_result_cid = "bafybeig2bqbxhk42aznq6fap4ubbfg4zqcmdc27lb4iaymslcat56tayam"

    expected_block_result_hash =
      <<28, 194, 179, 26, 109, 156, 17, 247, 235, 26, 218, 252, 146, 109, 254, 149, 146, 8, 79,
        252, 221, 91, 204, 188, 78, 17, 60, 177, 236, 150, 45, 1>>

    assert status == :ok
    assert cid == expected_block_result_cid
    assert block_result_hash == expected_block_result_hash
  end
end
