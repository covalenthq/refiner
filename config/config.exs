# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

config :machine_gun,
  rpc_pool: %{
    conn_opts: %{
      tls_opts: [verify: :verify_none]
    },
    pool_size: 32,
    pool_max_overflow: 0,
    pool_timeout: 1_200_000
  }

config :porcelain, driver: Porcelain.Driver.Basic

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
