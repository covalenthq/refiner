defmodule Rudder.SourceDiscovery do
  use GenServer

  @impl true
  def init(_) do
    {:ok, []}
  end

  def start_link(_) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  @impl true
  def handle_call({:fetch, urls}, _from, state) do
    url = Enum.at(urls, 0)
    ["ipfs", cid] = String.split(url, "://")

    result = Rudder.IPFSInteractor.fetch(cid)
    {:reply, result, state}
  end

  def discover(urls) do
    GenServer.call(Rudder.SourceDiscovery, {:fetch, urls}, :infinity)
  end
end
