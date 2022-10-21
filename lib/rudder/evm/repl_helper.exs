# helper which aggregates sequence of statements which is needed for executing
# the block processor in the iex shell. Do not call in production.
defmodule BlockProcessorReplHelper do
  alias Rudder.BlockProcessor

  def test(is_sync) do
    Code.compile_file("lib/rudder/evm/block_processor.ex")
    Code.compile_file("lib/rudder/evm/repl_helper.ex")
    Code.compile_file("lib/rudder/evm/structs.ex")
    Code.compile_file("lib/rudder/evm/workers.ex")
    pid = Process.whereis(:evm_pool_supervisor)

    if pid != nil and Process.alive?(pid) do
      BlockProcessor.stop()
    end

    BlockProcessor.start(10)
    queue_test(is_sync)
  end

  def queue_test(is_sync) do
    block_id = "1234_" <> Atom.to_string(is_sync)

    {:ok, contents1} = File.read("../../../test-data/block-specimen/15548376.specimen.json")

    {:ok, contents2} = File.read("../../../test-data/block-specimen/15557220.specimen.json")

    lmbd1 = fn -> BlockProcessor.sync_queue({block_id, contents1}) end
    lmbd2 = fn -> BlockProcessor.sync_queue({block_id <> "_2", contents2}) end

    lmbd3 = fn ->
      BlockProcessor.sync_queue({block_id <> "_3", "[" <> contents2 <> "]"})
    end

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
