defmodule Refiner.BlockResultUploaderTest do
  use ExUnit.Case, async: true

  setup_all do
    block_result_uploader = start_supervised!(Refiner.BlockResultUploader)
    ipfs_interactor = start_supervised!(Refiner.IPFSInteractor)

    %{block_result_uploader: block_result_uploader, ipfs_interactor: ipfs_interactor}
  end

  test "uploads block result to ipfs and sends the block result hash to proof chain", %{
    block_result_uploader: _block_result_uploader,
    ipfs_interactor: _ipfs_interactor
  } do
    # "bafkreiehfggmf4y7xjzrqhvcvhto6eg44ipnsxuyxwwjytqvatvbn5eg4q"
    expected_cid = "bafkreibm6jg3ux5qumhcn2b3flc3tyu6dmlb4xa7u5bf44yegnrjhc4yeq"

    # tests would be started from project root rather than test/
    file_path = Path.expand(Path.absname(Path.relative_to_cwd("test-data/temp2.txt")))

    expected_block_result_hash =
      <<44, 242, 77, 186, 95, 176, 163, 14, 38, 232, 59, 42, 197, 185, 226, 158, 27, 22, 30, 92,
        31, 167, 66, 94, 115, 4, 51, 98, 147, 139, 152, 36>>

    block_result_metadata = %Refiner.BlockResultMetadata{
      chain_id: 1,
      block_height: 1,
      block_specimen_hash: "525D191D6492F1E0928d4e816c29778c",
      file_path: file_path
    }

    {error, cid, block_result_hash} =
      Refiner.BlockResultUploader.upload_block_result(block_result_metadata)

    assert error == :ok
    assert cid == expected_cid
    assert block_result_hash == expected_block_result_hash
  end

  test "ipfs contains cid with known cid", %{
    ipfs_interactor: _ipfs_interactor,
    block_result_uploader: _block_result_uploader
  } do
    file_path = Path.expand(Path.absname(Path.relative_to_cwd("test-data/temp.txt")))
    {err, cid} = Refiner.IPFSInteractor.pin(file_path)
    expected_cid = "bafkreiehfggmf4y7xjzrqhvcvhto6eg44ipnsxuyxwwjytqvatvbn5eg4q"

    assert err == :ok
    assert cid == expected_cid
  end

  test "the server works", %{
    ipfs_interactor: _ipfs_interactor,
    block_result_uploader: _block_result_uploader
  } do
    ipfs_url = Application.get_env(:refiner, :ipfs_pinner_url)
    url = "#{ipfs_url}/upload"

    {err, _} =
      Finch.build(:get, "#{url}/upload")
      |> Finch.request(Refiner.Finch)

    assert err != :error
  end
end
