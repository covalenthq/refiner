defmodule Refiner.PipelineTest do
  use ExUnit.Case, async: true

  test "returns the cid and hash of the processed block hash", %{} do
    # encoded specimen file: ./test-data/codec-0.38/encoded/1-22433670(codec-0.38)
    test_urls = ["ipfs://bafybeies5axj3hr5ylotqqrwqyerrfiqfvvu6ad33xll7iah677bi46rdy"]
    expected_block_result_cid = "bafybeica3v7gpy25q6p5qegcm5rnbhf5fapsis55wklhtcry4l24hkw5py"
    test_block_specimen_hash = "4512cefa823fd5f879eac94991eabf7cb9f75ac36dd35e3f5d02897eb82e58b4"
    test_bsp_key = "1_1_1_" <> test_block_specimen_hash

    expected_block_result_hash =
      <<94, 3, 153, 91, 4, 158, 241, 28, 156, 152, 246, 254, 76, 109, 74, 215, 43, 106, 152, 255,
        213, 155, 118, 50, 107, 121, 221, 96, 132, 0, 109, 68>>

    {status, cid, block_result_hash} = Refiner.Pipeline.process_specimen(test_bsp_key, test_urls)

    assert status == :ok
    assert cid == expected_block_result_cid
    assert block_result_hash == expected_block_result_hash
  end

  test "pipeline spawner starts pipeline processes", %{} do
    # encoded specimen file: ./test-data/codec-0.38/encoded/1-22434160 (codec-0.38)
    test_urls = ["ipfs://bafybeifvxz5vzfzzolmninlvnwjiurc7jbwjbmyahsvtaczbi3wbuqhjce"]
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

    expected_block_result_cid = "bafybeifzwvad7ox6g4ujlpxgb5szv6rjw3o4efycegpstvfnyhtre7oh2u"

    expected_block_result_hash =
      <<107, 16, 247, 146, 61, 123, 156, 32, 183, 214, 199, 106, 205, 145, 245, 56, 36, 113, 176,
        204, 215, 245, 192, 185, 208, 146, 246, 248, 225, 185, 0, 195>>

    assert status == :ok
    assert cid == expected_block_result_cid
    assert block_result_hash == expected_block_result_hash
  end
end
