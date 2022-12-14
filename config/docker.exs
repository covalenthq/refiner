import Config

config :rudder,
  operator_private_key: "8b3a350cf5c34c9194ca85829a2df0ec3153be0318b5e2d3348e872092edffba",
  proofchain_address: "0xCF3d5540525D191D6492F1E0928d4e816c29778c",
  proofchain_chain_id: 31337,
  proofchain_node: System.get_env("NODE_ETHEREUM_MAINNET"),
  ipfs_pinner_url: System.get_env("IPFS_PINNER_URL")
