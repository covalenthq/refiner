defmodule Rudder.Telemetry do
  use Supervisor
  import Telemetry.Metrics

  @spec start_link(any) :: :ignore | {:error, any} | {:ok, pid}
  def start_link(arg) do
    Supervisor.start_link(__MODULE__, arg, name: __MODULE__)
  end

  def init(_arg) do
    metrics = [
      # event_emitting (all available metrics for any event)
      counter("rudder.events.emit.duration",
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
      counter("rudder.events.ipfs_pin.duration",
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
      counter("rudder.events.ipfs_fetch.duration",
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
      counter("rudder.events.bsp_decode.duration",
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
      counter("rudder.events.bsp_execute.duration",
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
      counter("rudder.events.brp_upload.duration",
        tags: [:table, :operation]
      ),
      last_value("rudder.events.brp_upload.duration",
        unit: {:native, :millisecond},
        tags: [:table, :operation]
      ),
      sum("rudder.events.brp_upload.duration",
        unit: {:native, :millisecond},
        tags: [:table, :operation]
      ),
      summary("rudder.events.brp_upload.duration",
        unit: {:native, :millisecond},
        tags: [:table, :operation]
      ),

      # brp_proofing
      counter("rudder.events.brp_proof.duration",
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

      # rudder_pipelining
      counter("rudder.events.rudder_pipeline.duration",
        tags: [:table, :operation]
      ),
      last_value("rudder.events.rudder_pipeline.duration",
        unit: {:native, :millisecond},
        tags: [:table, :operation]
      ),
      sum("rudder.events.rudder_pipeline.duration",
        unit: {:native, :millisecond},
        tags: [:table, :operation]
      ),
      summary("rudder.events.rudder_pipeline.duration",
        unit: {:native, :millisecond},
        tags: [:table, :operation]
      )
    ]

    children = [
      {Rudder.Telemetry.CustomReporter, metrics: metrics}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
