defmodule Rudder.Telemetry do
  use Supervisor
  import Telemetry.Metrics

  def start_link(arg) do
    Supervisor.start_link(__MODULE__, arg, name: __MODULE__)
  end

  def init(_arg) do
    children = [
      {Rudder.Telemetry.CustomReporter, metrics: metrics()}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

  defp metrics do
    [
      # ipfs_pinning
      counter("rudder.events.ipfs_pin.value"),
      sum("rudder.events.ipfs_pin.value"),
      # summary("rudder.events.ipfs_pin.value"),

      # ipfs_fetching
      counter("rudder.events.ipfs_fetch.value"),
      sum("rudder.events.ipfs_fetch.value"),
      # summary("rudder.events.ipfs_fetch.value"),

      # bsp_decoding
      counter("rudder.events.bsp_decode.value"),
      sum("rudder.events.bsp_decode.value"),
      # summary("rudder.events.bsp_decode.value"),

      # bsp_extracting
      counter("rudder.events.bsp_extract.value"),
      sum("rudder.events.bsp_extract.value"),
      # summary("rudder.events.bsp_extract.value"),

      # evm_executing
      counter("rudder.events.evm_execute.value"),
      sum("rudder.events.evm_execute.value"),
      # summary("rudder.events.evm_execute.value"),

      # brp_uploading
      counter("rudder.events.bsp_upload.value"),
      sum("rudder.events.bsp_upload.value"),
      # summary("rudder.events.bsp_upload.value"),

      # tx_proofing
      counter("rudder.events.tx_proof.value"),
      sum("rudder.events.tx_proof.value"),
      # summary("rudder.events.tx_proof.value"),

      # brp_pipelining
      counter("rudder.events.brp_pipeline.value"),
      sum("rudder.events.brp_pipeline.value")
      # summary("rudder.events.brp_pipeline.value")
    ]
  end
end
