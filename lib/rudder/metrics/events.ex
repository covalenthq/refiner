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
    :telemetry.execute([:rudder, :events, :bsp_decode], %{duration: duration}, %{
      table: "bsp_metrics",
      operation: "decode"
    })
  end

  @spec bsp_execute(any) :: :ok
  def bsp_execute(duration) do
    :telemetry.execute([:rudder, :events, :bsp_execute], %{duration: duration}, %{
      table: "bsp_metrics",
      operation: "execute"
    })
  end

  @spec brp_upload(any) :: :ok
  def brp_upload(duration) do
    :telemetry.execute([:rudder, :events, :brp_upload], %{duration: duration}, %{
      table: "brp_metrics",
      operation: "upload"
    })
  end

  @spec brp_proof(any) :: :ok
  def brp_proof(duration) do
    :telemetry.execute([:rudder, :events, :brp_proof], %{duration: duration}, %{
      table: "brp_metrics",
      operation: "proof"
    })
  end

  @spec rudder_pipeline(any) :: :ok
  def rudder_pipeline(duration) do
    :telemetry.execute([:rudder, :events, :rudder_pipeline], %{duration: duration}, %{
      table: "rudder_metrics",
      operation: "pipeline"
    })
  end
end
