defmodule Rudder.ProofChain.BlockResultEventListener do
  use GenServer

  @impl true
  def init(_) do
    proofchain_address = Application.get_env(:rudder, :proofchain_address)
    listen_for_event(proofchain_address)
    {:ok, []}
  end

  @brp_submitted_event_hash "0x8741f5bf89731b15f24deb1e84e2bbd381947f009ee378a2daa15ed8abfb9485"

  def start_link(_) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def start() do
    proofchain_address = Application.get_env(:rudder, :proofchain_address)
    listen_for_event(proofchain_address)
  end

  defp extract_submitted_specimens(log_events) do
    specimen_hashes_set =
      Enum.reduce(log_events, MapSet.new(), fn log_event, specimen_hashes ->
        event_signature = "(uint64,uint64,bytes32,bytes32,string,uint128)"

        [
          _chain_id,
          _block_height,
          specimen_hash_raw,
          _block_result_hash_raw,
          _url,
          _submittedStake
        ] = Rudder.Util.extract_data(log_event, event_signature)

        specimen_hash = Base.encode16(specimen_hash_raw, case: :lower)

        MapSet.put(specimen_hashes, specimen_hash)
      end)

    MapSet.to_list(specimen_hashes_set)
  end

  defp listen_for_event(proofchain_address) do
    {:ok, brp_submitted_logs} =
      Rudder.Network.EthereumMainnet.eth_getLogs([
        %{
          address: proofchain_address,
          fromBlock: "latest",
          topics: [@brp_submitted_event_hash]
        }
      ])

    unique_submitted_specimens = extract_submitted_specimens(brp_submitted_logs)

    Enum.each(unique_submitted_specimens, fn specimen_hash ->
      nil
      # GenServer.cast(Rudder.BlockSpecimenDiscoverer, {:push, specimen_hash})
    end)

    :timer.sleep(1000)
    listen_for_event(proofchain_address)
  end
end
