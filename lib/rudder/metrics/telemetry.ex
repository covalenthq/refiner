defmodule Rudder.Telemetry do
  use Supervisor
  import Telemetry.Metrics

  @spec start_link(any) :: :ignore | {:error, any} | {:ok, pid}
  def start_link(arg) do
    Supervisor.start_link(__MODULE__, arg, name: __MODULE__)
  end

  @spec init(any) :: {:ok, {%{intensity: any, period: any, strategy: any}, list}}
  def init(_arg) do
    metrics = [
      # event_emitting (all available metrics for any event)
      counter("rudder.events.emit.count",
        tags: [:table, :operation]
      ),
      last_value("rudder.events.emit.duration",
        unit: {:native, :millisecond},
        tags: [:table, :operation]
      ),
      sum("rudder.events.emit.duration",
        unit: {:native, :millisecond},
        tags: [:table, :operation]
      ),
      summary("rudder.events.emit.duration",
        unit: {:native, :millisecond},
        tags: [:table, :operation]
      ),
      distribution("rudder.events.emit.duration",
        unit: {:native, :millisecond},
        buckets: [0.0003, 0.0006, 0.0010],
        tags: [:table, :operation]
      ),

      # ipfs_pinning
      counter("rudder.events.ipfs_pin.count",
        tags: [:table, :operation]
      ),
      last_value("rudder.events.ipfs_pin.duration",
        unit: {:native, :millisecond},
        tags: [:table, :operation]
      ),
      sum("rudder.events.ipfs_pin.duration",
        unit: {:native, :millisecond},
        tags: [:table, :operation]
      ),
      summary("rudder.events.ipfs_pin.duration",
        unit: {:native, :millisecond},
        tags: [:table, :operation]
      ),

      # ipfs_fetching
      counter("rudder.events.ipfs_fetch.count",
        tags: [:table, :operation]
      ),
      last_value("rudder.events.ipfs_fetch.duration",
        unit: {:native, :millisecond},
        tags: [:table, :operation]
      ),
      sum("rudder.events.ipfs_fetch.duration",
        unit: {:native, :millisecond},
        tags: [:table, :operation]
      ),
      summary("rudder.events.ipfs_fetch.duration",
        unit: {:native, :millisecond},
        tags: [:table, :operation]
      ),

      # bsp_decoding
      counter("rudder.events.bsp_decode.count",
        tags: [:table, :operation]
      ),
      last_value("rudder.events.bsp_decode.duration",
        unit: {:native, :millisecond},
        tags: [:table, :operation]
      ),
      sum("rudder.events.bsp_decode.duration",
        unit: {:native, :millisecond},
        tags: [:table, :operation]
      ),
      summary("rudder.events.bsp_decode.duration",
        unit: {:native, :millisecond},
        tags: [:table, :operation]
      ),

      # bsp_executing
      counter("rudder.events.bsp_execute.count",
        tags: [:table, :operation]
      ),
      last_value("rudder.events.bsp_execute.duration",
        unit: {:native, :millisecond},
        tags: [:table, :operation]
      ),
      sum("rudder.events.bsp_execute.duration",
        unit: {:native, :millisecond},
        tags: [:table, :operation]
      ),
      summary("rudder.events.bsp_execute.duration",
        unit: {:native, :millisecond},
        tags: [:table, :operation]
      ),

      # brp_uploading
      counter("rudder.events.brp_upload_success.count",
        tags: [:table, :operation]
      ),
      last_value("rudder.events.brp_upload_success.duration",
        unit: {:native, :millisecond},
        tags: [:table, :operation]
      ),
      sum("rudder.events.brp_upload_success.duration",
        unit: {:native, :millisecond},
        tags: [:table, :operation]
      ),
      summary("rudder.events.brp_upload_success.duration",
        unit: {:native, :millisecond},
        tags: [:table, :operation]
      ),
      counter("rudder.events.brp_upload_failure.count",
        tags: [:table, :operation]
      ),
      last_value("rudder.events.brp_upload_failure.duration",
        unit: {:native, :millisecond},
        tags: [:table, :operation]
      ),
      sum("rudder.events.brp_upload_failure.duration",
        unit: {:native, :millisecond},
        tags: [:table, :operation]
      ),
      summary("rudder.events.brp_upload_failure.duration",
        unit: {:native, :millisecond},
        tags: [:table, :operation]
      ),

      # brp_proofing
      counter("rudder.events.brp_proof.count",
        tags: [:table, :operation]
      ),
      last_value("rudder.events.brp_proof.duration",
        unit: {:native, :millisecond},
        tags: [:table, :operation]
      ),
      sum("rudder.events.brp_proof.duration",
        unit: {:native, :millisecond},
        tags: [:table, :operation]
      ),
      summary("rudder.events.brp_proof.duration",
        unit: {:native, :millisecond},
        tags: [:table, :operation]
      ),

      # journal_fetching
      counter("rudder.events.journal_fetch_last.count",
        tags: [:table, :operation]
      ),
      last_value("rudder.events.journal_fetch_last.duration",
        unit: {:native, :millisecond},
        tags: [:table, :operation]
      ),
      sum("rudder.events.journal_fetch_last.duration",
        unit: {:native, :millisecond},
        tags: [:table, :operation]
      ),
      summary("rudder.events.journal_fetch_last.duration",
        unit: {:native, :millisecond},
        tags: [:table, :operation]
      ),
      counter("rudder.events.journal_fetch_items.count",
        tags: [:table, :operation]
      ),
      last_value("rudder.events.journal_fetch_items.duration",
        unit: {:native, :millisecond},
        tags: [:table, :operation]
      ),
      sum("rudder.events.journal_fetch_items.duration",
        unit: {:native, :millisecond},
        tags: [:table, :operation]
      ),
      summary("rudder.events.journal_fetch_items.duration",
        unit: {:native, :millisecond},
        tags: [:table, :operation]
      ),

      # rudder_pipelining
      counter("rudder.events.rudder_pipeline_success.count",
        tags: [:table, :operation]
      ),
      last_value("rudder.events.rudder_pipeline_success.duration",
        unit: {:native, :millisecond},
        tags: [:table, :operation]
      ),
      sum("rudder.events.rudder_pipeline_success.duration",
        unit: {:native, :millisecond},
        tags: [:table, :operation]
      ),
      summary("rudder.events.rudder_pipeline_success.duration",
        unit: {:native, :millisecond},
        tags: [:table, :operation]
      ),
      counter("rudder.events.rudder_pipeline_failure.count",
        tags: [:table, :operation]
      ),
      last_value("rudder.events.rudder_pipeline_failure.duration",
        unit: {:native, :millisecond},
        tags: [:table, :operation]
      ),
      sum("rudder.events.rudder_pipeline_failure.duration",
        unit: {:native, :millisecond},
        tags: [:table, :operation]
      ),
      summary("rudder.events.rudder_pipeline_failure.duration",
        unit: {:native, :millisecond},
        tags: [:table, :operation]
      )
    ]

    children = [
      {Rudder.Telemetry.CustomReporter, metrics: metrics},
      {TelemetryMetricsPrometheus, metrics: metrics}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
