defmodule Rudder.Telemetry do
  use Supervisor
  import Telemetry.Metrics

  def start_link(arg) do
    Supervisor.start_link(__MODULE__, arg, name: __MODULE__)
  end

  def init(_arg) do
    children = [
      {Rudder.Telemetry.CustomReporter, metrics: metrics()}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

  defp metrics do
    [
      # event_emitting
      counter("rudder.events.emit.value"),
      sum("rudder.events.emit.value"),
      # summary("rudder.events.emit.value"),
      # ipfs_pinning
      counter("rudder.events.ipfs_pin.value"),
      sum("rudder.events.ipfs_pin.value"),
      # summary("rudder.events.ipfs_pin.value"),
      # ipfs_fetching
      counter("rudder.events.ipfs_fetch.value"),
      sum("rudder.events.ipfs_fetch.value")
      # summary("rudder.events.ipfs_fetch.value")
    ]
  end
end
