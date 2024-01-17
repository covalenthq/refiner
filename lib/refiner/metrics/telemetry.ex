defmodule Refiner.Telemetry do
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
      counter("refiner.events.emit.count",
        tags: [:table, :operation]
      ),
      last_value("refiner.events.emit.duration",
        unit: {:native, :millisecond},
        tags: [:table, :operation]
      ),
      # sum("refiner.events.emit.duration",
      #   unit: {:native, :millisecond},
      #   tags: [:table, :operation]
      # ),
      # distribution("refiner.events.emit.duration",
      #   unit: {:native, :millisecond},
      #   buckets: [0.0003, 0.0006, 0.0010],
      #   tags: [:table, :operation]
      # ),

      # ipfs_pinning
      counter("refiner.events.ipfs_pin.count",
        tags: [:table, :operation]
      ),
      last_value("refiner.events.ipfs_pin.duration",
        unit: {:native, :millisecond},
        tags: [:table, :operation]
      ),
      # sum("refiner.events.ipfs_pin.duration",
      #   unit: {:native, :millisecond},
      #   tags: [:table, :operation]
      # ),

      # ipfs_fetching
      counter("refiner.events.ipfs_fetch.count",
        tags: [:table, :operation]
      ),
      last_value("refiner.events.ipfs_fetch.duration",
        unit: {:native, :millisecond},
        tags: [:table, :operation]
      ),
      # sum("refiner.events.ipfs_fetch.duration",
      #   unit: {:native, :millisecond},
      #   tags: [:table, :operation]
      # ),

      # bsp_decoding
      counter("refiner.events.bsp_decode.count",
        tags: [:table, :operation]
      ),
      last_value("refiner.events.bsp_decode.duration",
        unit: {:native, :millisecond},
        tags: [:table, :operation]
      ),
      # sum("refiner.events.bsp_decode.duration",
      #   unit: {:native, :millisecond},
      #   tags: [:table, :operation]
      # ),

      # bsp_executing
      counter("refiner.events.bsp_execute.count",
        tags: [:table, :operation]
      ),
      last_value("refiner.events.bsp_execute.duration",
        unit: {:native, :millisecond},
        tags: [:table, :operation]
      ),
      # sum("refiner.events.bsp_execute.duration",
      #   unit: {:native, :millisecond},
      #   tags: [:table, :operation]
      # ),

      # brp_uploading
      counter("refiner.events.brp_upload_success.count",
        tags: [:table, :operation]
      ),
      last_value("refiner.events.brp_upload_success.duration",
        unit: {:native, :millisecond},
        tags: [:table, :operation]
      ),
      # sum("refiner.events.brp_upload_success.duration",
      #   unit: {:native, :millisecond},
      #   tags: [:table, :operation]
      # ),
      counter("refiner.events.brp_upload_failure.count",
        tags: [:table, :operation]
      ),
      last_value("refiner.events.brp_upload_failure.duration",
        unit: {:native, :millisecond},
        tags: [:table, :operation]
      ),
      # sum("refiner.events.brp_upload_failure.duration",
      #   unit: {:native, :millisecond},
      #   tags: [:table, :operation]
      # ),

      # brp_proofing
      counter("refiner.events.brp_proof.count",
        tags: [:table, :operation]
      ),
      last_value("refiner.events.brp_proof.duration",
        unit: {:native, :millisecond},
        tags: [:table, :operation]
      ),
      # sum("refiner.events.brp_proof.duration",
      #   unit: {:native, :millisecond},
      #   tags: [:table, :operation]
      # ),

      # journal_fetching
      counter("refiner.events.journal_fetch_last.count",
        tags: [:table, :operation]
      ),
      last_value("refiner.events.journal_fetch_last.duration",
        unit: {:native, :millisecond},
        tags: [:table, :operation]
      ),
      # sum("refiner.events.journal_fetch_last.duration",
      #   unit: {:native, :millisecond},
      #   tags: [:table, :operation]
      # ),
      counter("refiner.events.journal_fetch_items.count",
        tags: [:table, :operation]
      ),
      last_value("refiner.events.journal_fetch_items.duration",
        unit: {:native, :millisecond},
        tags: [:table, :operation]
      ),
      # sum("refiner.events.journal_fetch_items.duration",
      #   unit: {:native, :millisecond},
      #   tags: [:table, :operation]
      # ),

      # refiner_pipelining
      counter("refiner.events.refiner_pipeline_success.count",
        tags: [:table, :operation]
      ),
      last_value("refiner.events.refiner_pipeline_success.duration",
        unit: {:native, :millisecond},
        tags: [:table, :operation]
      ),
      # sum("refiner.events.refiner_pipeline_success.duration",
      #   unit: {:native, :millisecond},
      #   tags: [:table, :operation]
      # ),
      counter("refiner.events.refiner_pipeline_failure.count",
        tags: [:table, :operation]
      ),
      last_value("refiner.events.refiner_pipeline_failure.duration",
        unit: {:native, :millisecond},
        tags: [:table, :operation]
      )
      # sum("refiner.events.refiner_pipeline_failure.duration",
      #   unit: {:native, :millisecond},
      #   tags: [:table, :operation]
      # )
    ]

    children = [
      {Refiner.Telemetry.CustomReporter, metrics: metrics},
      {TelemetryMetricsPrometheus, metrics: metrics}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
