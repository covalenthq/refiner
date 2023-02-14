defmodule Rudder.Events do
  def emit(value) do
    :telemetry.execute([:rudder, :events, :emit], %{value: value})
  end

  def ipfs_pin(value) do
    :telemetry.execute([:rudder, :events, :ipfs_pin], %{value: value})
  end

  def ipfs_fetch(value) do
    :telemetry.execute([:rudder, :events, :ipfs_fetch], %{value: value})
  end
end
