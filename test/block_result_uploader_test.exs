defmodule Rudder.BlockResultUploaderTest do
  use ExUnit.Case, async: true

  setup do
    Porcelain.spawn("./server", [
      "-port",
      "3000",
      "-file",
      "temp.txt",
      "-jwt",
      "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJkaWQ6ZXRocjoweGMxQkE4ODRFNzczMjBBODQ2NDk4QjI1RDZmNWI4NWU1YkRENDViMTYiLCJpc3MiOiJ3ZWIzLXN0b3JhZ2UiLCJpYXQiOjE2NjE4OTk5MzE3NTAsIm5hbWUiOiJyZWZpbmVyLWlwZnMtcGlubmVyIn0.aX1F8S-dIGFKLa4vjQv8FEH-z_T3AU5z5DNyBUKRLOA"
    ])
    blockResultUploader = start_supervised!(Rudder.BlockResultUploader)
    %{blockResultUploader: blockResultUploader}


  end

  # test "ipfs contains cid", %{blockResultUploader: blockResultUploader} do
  #   assert Rudder.BlockResultUploader.lookup() == []

  #   Rudder.BlockResultUploader.pin("temp.txt")
  #   cid = Rudder.BlockResultUploader.lookup()

  #   {err, _} =
  #     Finch.build(:get, "https://dweb.link/ipfs/#{cid}")
  #     |> Finch.request(Rudder.Finch, receive_timeout: 50_000)

  #   assert err != :error
  # end

  test "ipfs contains cid with known cid", %{blockResultUploader: blockResultUploader} do
    Rudder.BlockResultUploader.pin("temp.txt")
    cid = "QmS21GuXiRMvJKHos4ZkEmQDmRBqRaF5tQS2CQCu2ne9sY"

    {err, _} =
      Finch.build(:get, "https://dweb.link/ipfs/#{cid}")
      |> Finch.request(Rudder.Finch, receive_timeout: 50_000)

    assert err != :error
  end
end
