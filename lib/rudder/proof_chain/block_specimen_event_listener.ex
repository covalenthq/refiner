defmodule Rudder.ProofChain.BlockSpecimenEventListener do
  use GenServer

  @impl true
  def init(_) do
    start()
    {:ok, []}
  end

  @proofchain_address "0xCF3d5540525D191D6492F1E0928d4e816c29778c"
  @bsp_submitted_event_hash "0x57b0cb34d2ff9ed661f8b3c684aaee6cbf0bda5da02f4044205556817fa8e76c"
  @bsp_awarded_event_hash "0xf05ac779af1ec75a7b2fbe9415b33a67c00294a121786f7ce2eb3f92e4a6424a"

  def start_link(_) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def start() do
    specimen_url_map = %{}
    listen_for_event(specimen_url_map)
  end


  defp extract_data(block_data, signature) do
    {:ok, data} = Map.fetch(block_data, "data")
    "0x" <> data = data
    fs = ABI.FunctionSelector.decode(signature)
    ABI.decode(fs, data |> Base.decode16!(case: :lower))
  end

  defp extract_submitted_specimens([], specimen_url_map), do: specimen_url_map

  defp extract_submitted_specimens(logs, specimen_url_map) do
    Enum.reduce(logs, specimen_url_map, fn (el, new_specimen_url_map) ->
      event_signature = "(uint64,uint64,bytes32,bytes32,string,uint128)"
      [chain_id, block_height, block_hash_raw, specimen_hash_raw, url, _submittedStake] = extract_data(el, event_signature)

      # prepare data to generate key
      specimen_hash = Base.encode16(specimen_hash_raw, case: :lower)
      block_hash = Base.encode16(block_hash_raw, case: :lower)

      key = to_string(chain_id) <> "_" <> to_string(block_height) <> "_" <> block_hash <> "_" <> specimen_hash

      urls = Map.get(specimen_url_map, key, [])
      urls = [url | urls]
      Map.put(new_specimen_url_map, key, urls)
    end)
  end

  defp extract_awarded_specimens([]), do: []

  defp extract_awarded_specimens(logs) do
    Enum.reduce(logs, [], fn (el, keys) ->

      {:ok, [_event_hash, chain_id_raw, block_height_raw, block_hash]} = Map.fetch(el, "topics")
      [specimen_hash_raw] = extract_data(el, "(bytes32)")

      # prepare data to generate key
      specimen_hash = Base.encode16(specimen_hash_raw, case: :lower)
      "0x" <> chain_id_raw = chain_id_raw
      "0x" <> block_height_raw = block_height_raw
      "0x" <> block_hash = block_hash
      {chain_id, _} = Integer.parse(chain_id_raw, 16)
      {block_height, _} = Integer.parse(block_height_raw, 16)

      key = to_string(chain_id) <> "_" <> to_string(block_height) <> "_" <> block_hash <> "_" <> specimen_hash

      [key | keys]
    end)
  end

  defp push_bsps_to_process([], specimen_url_map), do: specimen_url_map

  defp push_bsps_to_process(bsp_keys, specimen_url_map) do
    Enum.reduce(bsp_keys, specimen_url_map, fn (bsp_key, new_specimen_url_map) ->
      if Map.has_key?(specimen_url_map, bsp_key) do
        bsp_urls = Map.get(specimen_url_map, bsp_key)
        GenServer.cast(Rudder.SourceDiscovery, {:push, bsp_key, bsp_urls})
        Map.delete(new_specimen_url_map, bsp_key)
      else
        new_specimen_url_map
      end
    end
    )
  end


  defp listen_for_event(specimen_url_map) do

    {:ok, bsp_submitted_logs} = Rudder.Network.EthereumMainnet.eth_getLogs(
      [%{
        address: @proofchain_address,
        fromBlock: "latest",
        topics: [@bsp_submitted_event_hash]
      }]
    )
    specimen_url_map = extract_submitted_specimens(bsp_submitted_logs, specimen_url_map)

    # IO.inspect(specimen_url_map)

    {:ok, bsp_awarded_logs} = Rudder.Network.EthereumMainnet.eth_getLogs(
      [%{
        address: @proofchain_address,
        fromBlock: "latest",
        topics: [@bsp_awarded_event_hash]
      }]
    )
    # IO.inspect(bsp_awarded_logs)
    bsps_to_process = extract_awarded_specimens(bsp_awarded_logs)

    specimen_url_map = push_bsps_to_process(bsps_to_process, specimen_url_map)

    :timer.sleep(1000)
    listen_for_event(specimen_url_map)
  end

end
