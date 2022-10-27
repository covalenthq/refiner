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

  def get_specimen_file_path(specimena_hash) do
    "ipfs://" <> cid = "ipfs://QmenLp8RvB69Uk3G4udJWVqBVPkReZPW5AMikqoraGm6Bv"

    # use this while we do not have the source discovery implemented
    temp_test_path = "test-data/block-specimens/1-15127599-replica-0x167a4a9380713f133aa55f251fd307bd88dfd9ad1f2087346e1b741ff47ba7f5"
    temp_test_path
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
