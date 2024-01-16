defmodule Refiner.Events do
  @spec emit :: :ok
  def emit() do
    start_emit_ms = System.monotonic_time(:millisecond)
    random_number = :rand.uniform(9)
    :timer.sleep(100 * random_number)
    stop_emit_ms = System.monotonic_time(:millisecond)

    :telemetry.execute([:refiner, :events, :emit], %{duration: stop_emit_ms - start_emit_ms}, %{
      table: "emit_metrics",
      operation: "event"
    })
  end

  @spec ipfs_pin(any) :: :ok
  def ipfs_pin(duration) do
    :telemetry.execute([:refiner, :events, :ipfs_pin], %{duration: duration}, %{
      table: "ipfs_metrics",
      operation: "pin"
    })
  end

  @spec ipfs_fetch(any) :: :ok
  def ipfs_fetch(duration) do
    :telemetry.execute([:refiner, :events, :ipfs_fetch], %{duration: duration}, %{
      table: "ipfs_metrics",
      operation: "fetch"
    })
  end

  @spec bsp_decode(any) :: :ok
  def bsp_decode(duration) do
    :telemetry.execute([:refiner, :events, :bsp_decode], %{duration: duration}, %{
      table: "bsp_metrics",
      operation: "decode"
    })
  end

  @spec bsp_execute(any) :: :ok
  def bsp_execute(duration) do
    :telemetry.execute([:refiner, :events, :bsp_execute], %{duration: duration}, %{
      table: "bsp_metrics",
      operation: "execute"
    })
  end

  @spec brp_upload_success(any) :: :ok
  def brp_upload_success(duration) do
    :telemetry.execute([:refiner, :events, :brp_upload_success], %{duration: duration}, %{
      table: "brp_metrics",
      operation: "upload_success"
    })
  end

  @spec brp_upload_failure(any) :: :ok
  def brp_upload_failure(duration) do
    :telemetry.execute([:refiner, :events, :brp_upload_failure], %{duration: duration}, %{
      table: "brp_metrics",
      operation: "upload_failure"
    })
  end

  @spec brp_proof(any) :: :ok
  def brp_proof(duration) do
    :telemetry.execute([:refiner, :events, :brp_proof], %{duration: duration}, %{
      table: "brp_metrics",
      operation: "proof"
    })
  end

  @spec journal_fetch_last(any) :: :ok
  def journal_fetch_last(duration) do
    :telemetry.execute([:refiner, :events, :journal_fetch_last], %{duration: duration}, %{
      table: "journal_metrics",
      operation: "fetch_last"
    })
  end

  @spec journal_fetch_items(any) :: :ok
  def journal_fetch_items(duration) do
    :telemetry.execute([:refiner, :events, :journal_fetch_items], %{duration: duration}, %{
      table: "journal_metrics",
      operation: "fetch_items"
    })
  end

  @spec refiner_pipeline_success(any) :: :ok
  def refiner_pipeline_success(duration) do
    :telemetry.execute([:refiner, :events, :refiner_pipeline_success], %{duration: duration}, %{
      table: "refiner_metrics",
      operation: "pipeline_success"
    })
  end

  @spec refiner_pipeline_failure(any) :: :ok
  def refiner_pipeline_failure(duration) do
    :telemetry.execute([:refiner, :events, :refiner_pipeline_failure], %{duration: duration}, %{
      table: "refiner_metrics",
      operation: "pipeline_failure"
    })
  end
end
