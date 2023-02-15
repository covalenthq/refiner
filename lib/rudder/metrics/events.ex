defmodule Rudder.Events do
  @spec emit :: :ok
  def emit() do
    start_emit_ms = System.monotonic_time(:millisecond)
    random_number = :rand.uniform(9)
    :timer.sleep(100 * random_number)

    :telemetry.execute(
      [:rudder, :events, :emit],
      %{
        duration: System.monotonic_time(:millisecond) - start_emit_ms
      },
      %{table: "emit_metrics", operation: "event"}
    )
  end

  @spec ipfs_pin(any) :: :ok
  def ipfs_pin(duration) do
    :telemetry.execute([:rudder, :events, :ipfs_pin], %{duration: duration}, %{
      table: "ipfs_metrics",
      operation: "pin"
    })
  end

  @spec ipfs_fetch(any) :: :ok
  def ipfs_fetch(duration) do
    :telemetry.execute([:rudder, :events, :ipfs_fetch], %{duration: duration}, %{
      table: "ipfs_metrics",
      operation: "fetch"
    })
  end

  @spec bsp_decode(any) :: :ok
  def bsp_decode(duration) do
    :telemetry.execute([:rudder, :events, :bsp_decode], %{duration: duration})
  end

  @spec bsp_extract(any) :: :ok
  def bsp_extract(duration) do
    :telemetry.execute([:rudder, :events, :bsp_extract], %{duration: duration})
  end

  @spec evm_execute(any) :: :ok
  def evm_execute(duration) do
    :telemetry.execute([:rudder, :events, :evm_execute], %{duration: duration})
  end

  @spec brp_upload(any) :: :ok
  def brp_upload(duration) do
    :telemetry.execute([:rudder, :events, :brp_upload], %{duration: duration})
  end

  @spec tx_proof(any) :: :ok
  def tx_proof(duration) do
    :telemetry.execute([:rudder, :events, :tx_proof], %{duration: duration})
  end

  @spec brp_pipeline(any) :: :ok
  def brp_pipeline(duration) do
    :telemetry.execute([:rudder, :events, :brp_pipeline], %{duration: duration})
  end
end
