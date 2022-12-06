defmodule Rudder.ProofChain.BlockSpecimenEventListener do
  use GenServer
  alias Rudder.Journal

  @impl true
  def init(_) do
    start()
    {:ok, []}
  end

  @bsp_submitted_event_hash "0x57b0cb34d2ff9ed661f8b3c684aaee6cbf0bda5da02f4044205556817fa8e76c"
  @bsp_awarded_event_hash "0xf05ac779af1ec75a7b2fbe9415b33a67c00294a121786f7ce2eb3f92e4a6424a"

  def start_link(_) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def start() do
    specimen_url_map = %{}
    proofchain_address = Application.get_env(:rudder, :proofchain_address)
    block_height = get_latest_block()
    listen_for_event(specimen_url_map, proofchain_address, block_height)
  end

  def get_latest_block() do
    return "latest"
  end

  defp extract_submitted_specimens([], specimen_url_map), do: specimen_url_map

  defp extract_submitted_specimens(log_events, specimen_url_map) do
    Enum.reduce(log_events, specimen_url_map, fn log_event, new_specimen_url_map ->
      event_signature = "(uint64,uint64,bytes32,bytes32,string,uint128)"

      [chain_id, block_height, block_hash_raw, specimen_hash_raw, url, _submittedStake] =
        Rudder.Util.extract_data(log_event, event_signature)

      # prepare data to generate key
      specimen_hash = Base.encode16(specimen_hash_raw, case: :lower)
      block_hash = Base.encode16(block_hash_raw, case: :lower)

      key =
        to_string(chain_id) <>
          "_" <> to_string(block_height) <> "_" <> block_hash <> "_" <> specimen_hash

      urls = Map.get(specimen_url_map, key, [])
      urls = [url | urls]
      Journal.discovered(key)
      Map.put(new_specimen_url_map, key, urls)
    end)
  end

  defp extract_awarded_specimens([]), do: []

  defp extract_awarded_specimens(log_events) do
    Enum.reduce(log_events, [], fn log_event, keys ->
      {:ok, [_event_hash, chain_id_raw, block_height_raw, block_hash]} =
        Map.fetch(log_event, "topics")

      [specimen_hash_raw] = Rudder.Util.extract_data(log_event, "(bytes32)")

      # prepare data to generate key
      specimen_hash = Base.encode16(specimen_hash_raw, case: :lower)
      "0x" <> chain_id_raw = chain_id_raw
      "0x" <> block_height_raw = block_height_raw
      "0x" <> block_hash = block_hash
      {chain_id, _} = Integer.parse(chain_id_raw, 16)
      {block_height, _} = Integer.parse(block_height_raw, 16)

      key =
        to_string(chain_id) <>
          "_" <> to_string(block_height) <> "_" <> block_hash <> "_" <> specimen_hash

      Journal.awarded(key)
      [key | keys]
    end)
  end

  defp push_bsps_to_process([], specimen_url_map), do: specimen_url_map

  defp push_bsps_to_process(bsp_keys, specimen_url_map) do
    Enum.reduce(bsp_keys, specimen_url_map, fn bsp_key, new_specimen_url_map ->
      if Map.has_key?(specimen_url_map, bsp_key) do
        bsp_urls = Map.get(specimen_url_map, bsp_key)
        Rudder.Pipeline.Spawner.push_hash(bsp_key, bsp_urls)
        Map.delete(new_specimen_url_map, bsp_key)
      else
        new_specimen_url_map
      end
    end)
  end

  defp listen_for_event(specimen_url_map, proofchain_address, block_height) do
    {:ok, bsp_submitted_logs} =
      Rudder.Network.EthereumMainnet.eth_getLogs([
        %{
          address: proofchain_address,
          fromBlock: block_height,
          topics: [@bsp_submitted_event_hash]
        }
      ])

    specimen_url_map = extract_submitted_specimens(bsp_submitted_logs, specimen_url_map)

    {:ok, bsp_awarded_logs} =
      Rudder.Network.EthereumMainnet.eth_getLogs([
        %{
          address: proofchain_address,
          fromBlock: block_height,
          topics: [@bsp_awarded_event_hash]
        }
      ])

    bsps_to_process = extract_awarded_specimens(bsp_awarded_logs)

    specimen_url_map = push_bsps_to_process(bsps_to_process, specimen_url_map)

    latest_block_number = Rudder.Network.EthereumMainnet.eth_blockNumber()
    if latest_block_number == block_height do
      :timer.sleep(12000)
    end

    listen_for_event(specimen_url_map, proofchain_address, block_height + 1)
  end
end
