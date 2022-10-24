defmodule Rudder.BlockProcessor do
  alias Rudder.BlockProcessor.Core

  @doc """
  Starts a worker pool with given maximum number of workers (not enforced right now).
  """
  def start(workers_limit \\ 10) do
    Core.PoolSupervisor.start_link(workers_limit)
  end

  @doc """
  Stops the block processor worker pool
  """
  def stop() do
    Core.PoolSupervisor.stop()
  end

  @doc """
  Sends a synchronous request to the worker pool for manufacturing block result from the given block specimen contents
  """
  def sync_queue({block_id, contents}) do
    Core.Server.sync_queue({block_id, contents})
  end
end