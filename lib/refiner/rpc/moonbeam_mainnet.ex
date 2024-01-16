defmodule Refiner.Network.MoonbeamMainnet do
  use Refiner.RPC.EthereumClient,
    otp_app: :refiner,
    client_opts: Application.get_env(:refiner, :proofchain_node),
    chain_id: Application.get_env(:refiner, :proofchain_chain_id),
    description: "Moonbeam Foundation Mainnet",
    currency: [name: "Glimmer", ticker_symbol: "GLMR"]
end
