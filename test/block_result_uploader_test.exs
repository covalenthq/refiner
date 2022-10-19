defmodule Rudder.BlockResultUploaderTest do
  use ExUnit.Case, async: true

  setup_all do
    blockResultUploader = start_supervised!(Rudder.BlockResultUploader)
    iPFSInteractor = start_supervised!(Rudder.IPFSInteractor)

    # on_exit(fn ->
    #   :exec.kill(ipfs_node_process, 0)
    #   :exec.kill(docker_compose_process, 0)
    #   :exec.run("sudo rm ~/.ipfs/datastore/LOCK", [])
    #   :exec.run("sudo rm ~/.ipfs/repo.lock", [])
    # end)

    %{blockResultUploader: blockResultUploader, iPFSInteractor: iPFSInteractor}
  end

  # test "uploads block result to ipfs and sends the block result hash to proof chain", %{
  #   blockResultUploader: blockResultUploader,
  #   iPFSInteractor: iPFSInteractor
  # } do

  #   expected_cid = "QmS21GuXiRMvJKHos4ZkEmQDmRBqRaF5tQS2CQCu2ne9sY"

  #   expected_block_result_hash =
  #     <<3, 75, 152, 63, 79, 210, 203, 120, 23, 170, 198, 170, 197, 60, 162, 239, 213, 222, 38,
  #       232, 103, 76, 199, 41, 238, 191, 219, 250, 109, 168, 136, 237>>

  #   {error, cid, block_result_hash} =
  #     Rudder.BlockResultUploader.upload_block_result(
  #       1,
  #       1,
  #       "525D191D6492F1E0928d4e816c29778c",
  #       "./temp.txt"
  #     )
  #     IO.inspect(block_result_hash)

  #   assert error == :ok
  #   assert cid == expected_cid
  #   assert block_result_hash == expected_block_result_hash
  # end

  test "ipfs contains cid with known cid", %{
    iPFSInteractor: iPFSInteractor,
    blockResultUploader: blockResultUploader
  } do
    {:ok, current_dir} = File.cwd()
    {err, cid} = Rudder.IPFSInteractor.pin("./temp.txt")
    expected_cid = "QmS21GuXiRMvJKHos4ZkEmQDmRBqRaF5tQS2CQCu2ne9sY"
    IO.inspect({err, cid})

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
