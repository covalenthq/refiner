# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :rudder,
  ipfs_pinner_port: 3000,
  backlog_filepath: "specimen_backlog.txt",
  operator_private_key: System.get_env("BLOCK_RESULT_OPERATOR_PRIVATE_KEY"),
  proofchain_address: "0x4f2E285227D43D9eB52799D0A28299540452446E"

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

config :porcelain, driver: Porcelain.Driver.Basic

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
