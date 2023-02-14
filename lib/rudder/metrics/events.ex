defmodule Rudder.Events do
  def emit() do
    start_emit_ms = System.monotonic_time(:millisecond)
    random_number = :rand.uniform(9)
    :timer.sleep(100 * random_number)

    :telemetry.execute([:rudder, :events, :emit], %{
      duration: System.monotonic_time(:millisecond) - start_emit_ms
    })
  end

  def ipfs_pin(value) do
    :telemetry.execute([:rudder, :events, :ipfs_pin], %{value: value})
  end

  def ipfs_fetch(value) do
    :telemetry.execute([:rudder, :events, :ipfs_fetch], %{value: value})
  end

  def bsp_decode(value) do
    :telemetry.execute([:rudder, :events, :bsp_decode], %{value: value})
  end

  def bsp_extract(value) do
    :telemetry.execute([:rudder, :events, :bsp_extract], %{value: value})
  end

  def evm_execute(value) do
    :telemetry.execute([:rudder, :events, :evm_execute], %{value: value})
  end

  def brp_upload(value) do
    :telemetry.execute([:rudder, :events, :brp_upload], %{value: value})
  end

  def tx_proof(value) do
    :telemetry.execute([:rudder, :events, :tx_proof], %{value: value})
  end

  def brp_pipeline(value) do
    :telemetry.execute([:rudder, :events, :brp_pipeline], %{value: value})
  end
end
