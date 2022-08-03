defmodule Rudder.SourceDiscovery do
  use GenServer

  @impl true
  def init(_) do
    {:ok, []}
  end

  def start_link(_) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  defp discover_source(specimen_key, urls) do
    [chain_id, block_height, block_hash, specimen_hash] = String.split(specimen_key, "_")
    # pull data from ipfs using the given urls and push the result for further processing?
    IO.inspect("Source Discovery received urls for the specimen hash: " <> specimen_hash)
    IO.inspect(urls)
    IO.inspect("")
  end

  @impl true
  def handle_cast({:push, specimen_key, urls}, state) do
    discover_source(specimen_key, urls)
    {:noreply, [state]}
  end
end
