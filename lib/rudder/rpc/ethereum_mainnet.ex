defmodule Rudder.Network.EthereumMainnet do
  use Rudder.RPC.EthereumClient,
    otp_app: :rudder,
    client_opts: {:system, "NODE_ETHEREUM_MAINNET", nil},
    chain_id: 1,
    description: "Ethereum Foundation Mainnet",
    currency: [name: "Ether", ticker_symbol: "ETH"]
end
