defmodule Rudder.BlockSpecimenDiscoverer do
  def discover_block_specimen(urls) do
    url = Enum.at(urls, 0)
    ["ipfs", cid] = String.split(url, "://")

    {:ok, response} = Rudder.IPFSInteractor.fetch(cid)
    {:ok, response.body}
  end
end
