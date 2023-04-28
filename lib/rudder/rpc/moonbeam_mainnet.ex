defmodule Rudder.Network.MoonbeamMainnet do
  use Rudder.RPC.EthereumClient,
    otp_app: :rudder,
    client_opts: Application.get_env(:rudder, :proofchain_node),
    chain_id: Application.get_env(:rudder, :proofchain_chain_id),
    description: "Moonbeam Foundation Mainnet",
    currency: [name: "Glimmer", ticker_symbol: "GLMR"]
end
