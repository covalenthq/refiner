defmodule Rudder.IPFSInteractorTest do
  use ExUnit.Case, async: true

  setup_all do
    ipfs_node_process =
      Porcelain.spawn_shell(
        "sudo ./server  -port 3000 -jwt eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJkaWQ6ZXRocjoweGMxQkE4ODRFNzczMjBBODQ2NDk4QjI1RDZmNWI4NWU1YkRENDViMTYiLCJpc3MiOiJ3ZWIzLXN0b3JhZ2UiLCJpYXQiOjE2NjE4OTk5MzE3NTAsIm5hbWUiOiJyZWZpbmVyLWlwZnMtcGlubmVyIn0.aX1F8S-dIGFKLa4vjQv8FEH-z_T3AU5z5DNyBUKRLOA"
      )

    # wait 30 seconds for ipfs to start
    :timer.sleep(10000)
    iPFSInteractor = start_supervised!(Rudder.IPFSInteractor)

    on_exit(fn ->
      Porcelain.Process.stop(ipfs_node_process)
      Porcelain.Process.await(ipfs_node_process)

      # sometimes stopping the ipfs process doesn't remove the lock, so we need to do it explicitly
      Porcelain.shell("sudo rm ~/.ipfs/repo.lock")
    end)

    %{iPFSInteractor: iPFSInteractor}
  end

  test "ipfs contains cid with known cid", %{iPFSInteractor: iPFSInteractor} do
    {:ok, current_dir} = File.cwd()
    file_path = current_dir <> "/test/test_file_to_upload.txt"
    {err, cid} = Rudder.IPFSInteractor.pin(file_path)
    expected_cid = "QmeeXyy9mwfXxpwwP1odEd4Eo3X4gPsjrDDWjbUnSYtwTH"

    assert cid = expected_cid
  end

  # test "ipfs contains cid", %{IPFSInteractor: IPFSInteractor} do
  #   assert Rudder.IPFSInteractor.lookup() = []

  #   {:ok, current_dir} = File.cwd()
  #   file_path = current_dir <> "/test/test_file_to_upload.txt"

  #   Rudder.IPFSInteractor.pin(current_dir)
  #   cid = Rudder.IPFSInteractor.lookup()

  #   {err, _} =
  #     Finch.build(:get, "https://dweb.link/ipfs/#{cid}")
  #     |> Finch.request(Rudder.Finch, receive_timeout: 50_000)

  #   assert err != :error
  # end
end
