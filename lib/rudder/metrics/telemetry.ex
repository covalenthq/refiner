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
        unit: {:native, :millisecond},
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
        unit: {:native, :millisecond},
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
        unit: {:native, :millisecond},
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
      )

      # # bsp_decoding
      # counter("rudder.events.bsp_decode.duration"),
      # sum("rudder.events.bsp_decode.duration", unit: {:native, :millisecond}),
      # summary("rudder.events.bsp_decode.duration", unit: {:native, :millisecond}),

      # # bsp_extracting
      # counter("rudder.events.bsp_extract.duration"),
      # sum("rudder.events.bsp_extract.duration", unit: {:native, :millisecond}),
      # summary("rudder.events.bsp_extract.duration", unit: {:native, :millisecond}),

      # # evm_executing
      # counter("rudder.events.evm_execute.duration"),
      # sum("rudder.events.evm_execute.duration", unit: {:native, :millisecond}),
      # summary("rudder.events.evm_execute.duration", unit: {:native, :millisecond}),

      # # brp_uploading
      # counter("rudder.events.bsp_upload.duration"),
      # sum("rudder.events.bsp_upload.duration", unit: {:native, :millisecond}),
      # summary("rudder.events.bsp_upload.duration", unit: {:native, :millisecond}),

      # # tx_proofing
      # counter("rudder.events.tx_proof.duration"),
      # sum("rudder.events.tx_proof.duration", unit: {:native, :millisecond}),
      # summary("rudder.events.tx_proof.duration", unit: {:native, :millisecond}),

      # # brp_pipelining
      # counter("rudder.events.brp_pipeline.duration"),
      # sum("rudder.events.brp_pipeline.duration", unit: {:native, :millisecond}),
      # summary("rudder.events.brp_pipeline.duration", unit: {:native, :millisecond})
    ]

    children = [
      {Rudder.Telemetry.CustomReporter, metrics: metrics}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
