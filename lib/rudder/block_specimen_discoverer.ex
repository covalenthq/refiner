defmodule Rudder.BlockSpecimenDiscoverer do
  use GenServer

  @impl true
  def init(_) do
    {:ok, []}
  end

  def start_link(_) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def discover_block_specimen(urls) do
    url = Enum.at(urls, 0)
    ["ipfs", cid] = String.split(url, "://")

    {:ok, response} = Rudder.IPFSInteractor.fetch(cid)
    {:ok, response.body}
  end

  def discover_block_specimen(specimen_hash) do
    # pull data from ipfs using the given specimen hash and push the result for further processing?
    IO.inspect("Source Discovery received the specimen hash: " <> specimen_hash)
    IO.inspect("")
  end

  @impl true
  def handle_cast({:push, _specimen_key, urls}, state) do
    discover_block_specimen(urls)
    {:noreply, [state]}
  end

  @impl true
  def handle_cast({:push, specimen_hash}, state) do
    discover_block_specimen(specimen_hash)
    {:noreply, [state]}
  end
end
