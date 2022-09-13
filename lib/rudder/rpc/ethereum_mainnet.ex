defmodule Rudder.Network.EthereumMainnet do
  use Rudder.RPC.EthereumClient,
    otp_app: :ingestor,
    # client_module: Rudder.RPC.JSONRPC.UnixDomainSocketClient,
    client_opts: {:system, "NODE_ETHEREUM_MAINNET", nil},
    chain_id: 1,
    description: "Ethereum Foundation Mainnet",
    consensus_paradigm: :proof_of_work,
    currency: [name: "Ether", ticker_symbol: "ETH"],
    registrar: "0xe3389675d0338462dc76c6f9a3e432550c36a142",
    preferred_database_prefix: {:system, "DB_SCHEMA_ETHEREUM_MAINNET", "chain_eth_mainnet"},
    discovery_delay: 2,
    batch_load_lag_source_by: 100

  # alias Rudder.Network.EthereumFoundationTracerAdjunct, as: Tracer

  def eth_call(call_tx, at_block \\ :latest) do
    if System.get_env("NODE_ETHEREUM_MAINNET_TRACER") do
      Process.put(:worker_3pcalls, Process.get(:worker_3pcalls, 0) + 1)
      Tracer.eth_call(call_tx, at_block)
    else
      super(call_tx, at_block)
    end
  end
end
