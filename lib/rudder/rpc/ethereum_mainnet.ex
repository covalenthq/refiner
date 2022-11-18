defmodule Rudder.Network.EthereumMainnet do
  use Rudder.RPC.EthereumClient,
    otp_app: :rudder,
    client_opts: Application.get_env(:rudder, :proofchain_node),
    chain_id: 1,
    description: "Ethereum Foundation Mainnet",
    currency: [name: "Ether", ticker_symbol: "ETH"]
end
