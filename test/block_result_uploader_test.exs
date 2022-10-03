defmodule Rudder.BlockResultUploaderTest do
  use ExUnit.Case, async: true

  setup do
    blockResultUploader = start_supervised!(Rudder.BlockResultUploader)
    %{blockResultUploader: blockResultUploader}
  end

  test "ipfs contains cid", %{blockResultUploader: blockResultUploader} do
    assert Rudder.BlockResultUploader.lookup() == []

    Rudder.BlockResultUploader.pin("temp.txt")
    cid = Rudder.BlockResultUploader.lookup()

    {err, _} =
      Finch.build(:get, "https://dweb.link/ipfs/#{cid}")
      |> Finch.request(Rudder.Finch, receive_timeout: 50_000)

    assert err != :error
  end

  test "ipfs contains cid with know cid", %{blockResultUploader: blockResultUploader} do
    Rudder.BlockResultUploader.pin("temp.txt")
    cid = "QmS21GuXiRMvJKHos4ZkEmQDmRBqRaF5tQS2CQCu2ne9sY"

    {err, _} =
      Finch.build(:get, "https://dweb.link/ipfs/#{cid}")
      |> Finch.request(Rudder.Finch, receive_timeout: 50_000)

    assert err != :error
  end
end
