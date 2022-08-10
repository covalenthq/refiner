import Config

config :ethereumex, url: "http://127.0.0.1:8545"

config :ethereumex, ipc_path: "#{System.user_home!()}/.local/share/io.parity.ethereum/jsonrpc.ipc"

config :ethereumex, id_reset: true
