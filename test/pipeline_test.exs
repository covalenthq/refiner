defmodule Rudder.PipelineTest do
  use ExUnit.Case, async: true

  test "returns the cid and hash of the processed block hash", %{} do
    test_urls = ["ipfs://QmR4BQi8fTdZM28GuWmtfjkbNPPzxiHCBNRXJng6rSEfcv"]
    expected_cid = "bafkreiawcv77lmfzm4wl2tmhtxx6zgkjo6eabxufjhulnbc4zk7pbg7ciy"

    expected_block_result_hash =
      <<22, 21, 127, 245, 176, 185, 103, 44, 189, 77, 135, 157, 239, 236, 153, 73, 119, 136, 0,
        222, 133, 73, 232, 182, 132, 92, 202, 190, 240, 155, 226, 70>>

    {status, cid, block_result_hash} = Rudder.Pipeline.pipeline("hash", test_urls)

    assert status == :ok
    assert cid == expected_cid
    assert block_result_hash == expected_block_result_hash
  end
end
