defmodule Rudder.Events do
  @spec emit :: :ok
  def emit() do
    start_emit_ms = System.monotonic_time(:millisecond)
    random_number = :rand.uniform(9)
    :timer.sleep(100 * random_number)

    :telemetry.execute([:rudder, :events, :emit], %{
      duration: System.monotonic_time(:millisecond) - start_emit_ms
    })
  end

  def ipfs_pin(duration) do
    :telemetry.execute([:rudder, :events, :ipfs_pin], %{duration: duration})
  end

  def ipfs_fetch(duration) do
    :telemetry.execute([:rudder, :events, :ipfs_fetch], %{duration: duration})
  end

  def bsp_decode(duration) do
    :telemetry.execute([:rudder, :events, :bsp_decode], %{duration: duration})
  end

  def bsp_extract(duration) do
    :telemetry.execute([:rudder, :events, :bsp_extract], %{duration: duration})
  end

  def evm_execute(duration) do
    :telemetry.execute([:rudder, :events, :evm_execute], %{duration: duration})
  end

  def brp_upload(duration) do
    :telemetry.execute([:rudder, :events, :brp_upload], %{duration: duration})
  end

  def tx_proof(duration) do
    :telemetry.execute([:rudder, :events, :tx_proof], %{duration: duration})
  end

  def brp_pipeline(duration) do
    :telemetry.execute([:rudder, :events, :brp_pipeline], %{duration: duration})
  end
end
