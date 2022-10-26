defmodule Rudder.SourceDiscovery do
  use GenServer

  @impl true
  def init(_) do
    {:ok, []}
  end

  def start_link(_) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  defp discover_source(_specimen_key, urls) do
    url = Enum.at(urls, 0)
    ["ipfs", cid] = String.split(url, "://")

    Rudder.IPFSInteractor.fetch(cid)
  end

  defp discover_source(specimen_hash) do
    # pull data from ipfs using the given specimen hash and push the result for further processing?
    IO.inspect("Source Discovery received the specimen hash: " <> specimen_hash)
    IO.inspect("")
  end

  @impl true
  def handle_cast({:push, specimen_key, urls}, state) do
    discover_source(specimen_key, urls)
    {:noreply, [state]}
  end

  @impl true
  def handle_cast({:push, specimen_hash}, state) do
    discover_source(specimen_hash)
    {:noreply, [state]}
  end
end
