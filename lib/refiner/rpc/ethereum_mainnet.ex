defmodule Refiner.Network.EthereumMainnet do
  use Refiner.RPC.EthereumClient,
    otp_app: :refiner,
    client_opts: Application.compile_env(:refiner, :proofchain_node),
    chain_id: Application.compile_env(:refiner, :proofchain_chain_id),
    description: "Ethereum Foundation Mainnet",
    currency: [name: "Ether", ticker_symbol: "ETH"]
end
