# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :rudder,
  ipfs_pinner_url: System.get_env("IPFS_PINNER_URL"),
  operator_private_key: System.get_env("BLOCK_RESULT_OPERATOR_PRIVATE_KEY"),
  proofchain_address: "0x4f2E285227D43D9eB52799D0A28299540452446E",
  proofchain_chain_id: 1284,
  proofchain_node: "https://rpc.api.moonbeam.network",
  journal_path: "logs/worklog.etf"

# Configures Elixir's Logger

# configuration for the {LoggerFileBackend, :error_log} backend
if config_env() == :dev || config_env() == :prod do
  config :logger,
    backends: [{LoggerFileBackend, :file_log}]

  config :logger, :file_log,
    path: "./logs/log.log",
    level: :info,
    rotate: %{max_bytes: 1_000_000, keep: 5},
    format: "$time $metadata[$level] $message\n",
    metadata: [:request_id, :file, :line]
end

# configuration of console
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

config :porcelain, driver: Porcelain.Driver.Basic

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
