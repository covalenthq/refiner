defmodule Rudder.IPFSInteractorTest do
  use ExUnit.Case, async: true

  setup do
    Porcelain.spawn("./server", [
      "-port",
      "3000",
      "-file",
      "/Users/fateme/elixirProjects/rudder/rudder/test_file_to_upload.txt",
      "-jwt",
      "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJkaWQ6ZXRocjoweGMxQkE4ODRFNzczMjBBODQ2NDk4QjI1RDZmNWI4NWU1YkRENDViMTYiLCJpc3MiOiJ3ZWIzLXN0b3JhZ2UiLCJpYXQiOjE2NjE4OTk5MzE3NTAsIm5hbWUiOiJyZWZpbmVyLWlwZnMtcGlubmVyIn0.aX1F8S-dIGFKLa4vjQv8FEH-z_T3AU5z5DNyBUKRLOA"
    ])

    iPFSInteractor = start_supervised!(Rudder.IPFSInteractor)
    %{iPFSInteractor: iPFSInteractor}
  end

  test "ipfs contains cid with known cid", %{iPFSInteractor: iPFSInteractor} do
    {err, cid} = Rudder.IPFSInteractor.pin("/Users/fateme/elixirProjects/rudder/rudder/test_file_to_upload.txt")
    # cid = "QmeeXyy9mwfXxpwwP1odEd4Eo3X4gPsjrDDWjbUnSYtwTH"


    assert err != :error
  end



    # test "ipfs contains cid", %{IPFSInteractor: IPFSInteractor} do
  #   assert Rudder.IPFSInteractor.lookup() == []

  #   Rudder.IPFSInteractor.pin("./test/test_file_to_upload.txt")
  #   cid = Rudder.IPFSInteractor.lookup()

  #   {err, _} =
  #     Finch.build(:get, "https://dweb.link/ipfs/#{cid}")
  #     |> Finch.request(Rudder.Finch, receive_timeout: 50_000)

  #   assert err != :error
  # end

end
