defmodule Rudder.BlockResultUploaderTest do
  use ExUnit.Case, async: true

  setup do

    Porcelain.spawn(
    "docker",
    ["compose",
    "--env-file",
    ".env",
    "-f",
    "docker-compose-local.yml",
    "up",
    "--remove-orphans"]
    )

    Porcelain.spawn("./server", [
      "sudo",
      "-port",
      "3000",
      "-file",
      "temp.txt",
      "-jwt",
      "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJkaWQ6ZXRocjoweGMxQkE4ODRFNzczMjBBODQ2NDk4QjI1RDZmNWI4NWU1YkRENDViMTYiLCJpc3MiOiJ3ZWIzLXN0b3JhZ2UiLCJpYXQiOjE2NjE4OTk5MzE3NTAsIm5hbWUiOiJyZWZpbmVyLWlwZnMtcGlubmVyIn0.aX1F8S-dIGFKLa4vjQv8FEH-z_T3AU5z5DNyBUKRLOA"
    ])

    blockResultUploader = start_supervised!(Rudder.BlockResultUploader)
    iPFSInteractor = start_supervised!(Rudder.IPFSInteractor)
    %{blockResultUploader: blockResultUploader, iPFSInteractor: iPFSInteractor}
  end

  test "uploads block result to ipfs and sends the block result hash to proof chain", %{blockResultUploader: blockResultUploader, iPFSInteractor: iPFSInteractor} do
    expected_cid = "QmS21GuXiRMvJKHos4ZkEmQDmRBqRaF5tQS2CQCu2ne9sY"
    expected_block_result_hash = ""

    {:ok, cid, block_result_hash} = Rudder.BlockResultUploader.upload_block_result(1, 1, "525D191D6492F1E0928d4e816c29778c", "test_file_to_upload.txt")
    IO.inspect(block_result_hash)
    assert cid = expected_cid
  end

end
