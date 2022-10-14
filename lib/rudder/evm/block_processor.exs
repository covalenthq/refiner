defmodule BPT do
  alias Rudder.BlockProcessor

  def test(is_sync) do
    Code.compile_file("lib/rudder/evm/block_result_gen.ex")
    pid = Process.whereis(:evm_poolsup)

    if pid != nil and Process.alive?(pid) do
      BlockProcessor.API.stop()
    end

    BlockProcessor.API.start(10)
    queue_test(is_sync)
  end

  def queue_test(is_sync) do
    block_id = "1234_" <> Atom.to_string(is_sync)

    {:ok, contents1} =
      File.read("/Users/sudeep/repos/bsp-agent/scripts/replica/15548376/segment.json")

    {:ok, contents2} =
      File.read("/Users/sudeep/repos/bsp-agent/scripts/replica/15582840/segment.json")

    lmbd1 = fn -> BlockProcessor.API.sync_queue({block_id, contents1}) end
    lmbd2 = fn -> BlockProcessor.API.sync_queue({block_id <> "_2", contents2}) end
    lmbd3 = fn -> BlockProcessor.API.sync_queue({block_id <> "_3", "[" <> contents2 <> "]"}) end

    if is_sync do
      lmbd1.()
      lmbd2.()
      lmbd3.()
    else
      Task.async(fn -> lmbd1.() end)
      Task.async(fn -> lmbd2.() end)
      Task.async(fn -> lmbd3.() end)
    end
  end
end
