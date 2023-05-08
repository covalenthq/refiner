# defmodule Rudder.Telemetry.Dashboards do
#   use PromEx, otp_app: :rudder

#   alias PromEx.Plugins

#   @impl true
#   def plugins do
#     [
#       # PromEx built in plugins
#       Plugins.Application,
#       Plugins.Beam
#       # Plugins.PlugCowboy
#       # Plugins.Finch,
#       # Plugins.Broadway
#     ]
#   end

#   @impl true
#   def dashboard_assigns do
#     [
#       datasource_id: "prometheus"
#     ]
#   end

#   @impl true
#   def dashboards do
#     [
#       # PromEx built in Grafana dashboards
#       {:prom_ex, "application.json"},
#       {:prom_ex, "beam.json"}
#       # {:prom_ex, "phoenix.json"},
#       # {:prom_ex, "phoenix_live_view.json"}
#     ]
#   end
# end
