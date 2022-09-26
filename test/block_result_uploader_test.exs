defmodule Rudder.BlockResultUploaderTest do
  use ExUnit.Case, async: true

  setup do
    blockResultUploader = start_supervised!(Rudder.BlockResultUploader)
    %{blockResultUploader: blockResultUploader}
  end

  test "ipfs contains cid", %{blockResultUploader: blockResultUploader} do
    assert Rudder.BlockResultUploader.lookup() == []

    Rudder.BlockResultUploader.pin("temp.txt")
    cid = "QmS21GuXiRMvJKHos4ZkEmQDmRBqRaF5tQS2CQCu2ne9sY"

    x = Finch.build(:get, "https://dweb.link/ipfs/#{cid}")
    |> Finch.request(Rudder.Finch, receive_timeout: 50_000)

    assert x != {:error, _}

  end

  test "ipfs contains cid", %{blockResultUploader: blockResultUploader} do
    assert Rudder.BlockResultUploader.lookup() == []

    Rudder.BlockResultUploader.pin("temp.txt")
    cid = Rudder.BlockResultUploader.lookup()
    cid = "QmS21GuXiRMvJKHos4ZkEmQDmRBqRaF5tQS2CQCu2ne9sY"

    x = Finch.build(:get, "https://dweb.link/ipfs/#{cid}")
    |> Finch.request(Rudder.Finch, receive_timeout: 50_000)

    assert x != {:error, _}

  end
end
