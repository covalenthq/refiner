defmodule Rudder.BlockResultUploaderTest do
  use ExUnit.Case, async: true

  setup_all do
    blockResultUploader = start_supervised!(Rudder.BlockResultUploader)
    iPFSInteractor = start_supervised!(Rudder.IPFSInteractor)

    %{blockResultUploader: blockResultUploader, iPFSInteractor: iPFSInteractor}
  end

  test "uploads block result to ipfs and sends the block result hash to proof chain", %{
    blockResultUploader: blockResultUploader,
    iPFSInteractor: iPFSInteractor
  } do
    expected_cid = "QmS21GuXiRMvJKHos4ZkEmQDmRBqRaF5tQS2CQCu2ne9sY"

    expected_block_result_hash =
      <<135, 41, 140, 194, 243, 31, 186, 115, 24, 30, 162, 169, 230, 239, 16, 220, 226, 30, 217,
        94, 152, 189, 172, 156, 78, 21, 4, 234, 22, 244, 134, 228>>

    block_result_metadata = %Rudder.BlockResultMetadata{
      chain_id: 1,
      block_height: 1,
      block_specimen_hash: "525D191D6492F1E0928d4e816c29778c",
      file_path: "./temp.txt"
    }

    {error, cid, block_result_hash} =
      Rudder.BlockResultUploader.upload_block_result(block_result_metadata)

    assert error == :ok
    assert cid == expected_cid
    assert block_result_hash == expected_block_result_hash
  end

  test "ipfs contains cid with known cid", %{
    iPFSInteractor: iPFSInteractor,
    blockResultUploader: blockResultUploader
  } do
    {:ok, current_dir} = File.cwd()
    {err, cid} = Rudder.IPFSInteractor.pin("./temp.txt")
    expected_cid = "QmS21GuXiRMvJKHos4ZkEmQDmRBqRaF5tQS2CQCu2ne9sY"

    assert err == :ok
    assert cid == expected_cid
  end

  test "the server works", %{
    iPFSInteractor: iPFSInteractor,
    blockResultUploader: blockResultUploader
  } do
    {err, _} =
      Finch.build(:get, "http://localhost:3001/pin")
      |> Finch.request(Rudder.Finch)

    assert err != :error
  end
end
