defmodule Rudder.BlockResultUploaderTest do
  use ExUnit.Case, async: true

  setup do
    blockResultUploader = start_supervised!(Rudder.BlockResultUploader)
    %{blockResultUploader: blockResultUploader}
  end

  test "uploader uploades", %{blockResultUploader: blockResultUploader} do
    assert Rudder.BlockResultUploader.lookup() == []

    Rudder.BlockResultUploader.pin("temp.txt")
    assert [{200, _}] = Rudder.BlockResultUploader.lookup()

  end
end
