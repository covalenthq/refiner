defmodule Rudder.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      {Finch,
       name: Rudder.Finch,
       pools: %{
         :default => [size: 32]
       }},
      {Rudder.IPFSInteractor, name: Rudder.IPFSInteractor},
      {Rudder.Journal, [Application.get_env(:rudder, :journal_path), name: Rudder.Journal]},
      Rudder.Avro.Client,
      {Rudder.Avro.BlockSpecimenDecoder, name: Rudder.Avro.BlockSpecimenDecoder},
      {Rudder.BlockResultUploader, name: Rudder.BlockResultUploader},
      %{
        id: Rudder.BlockProcessor.Core.PoolSupervisor,
        start: {Rudder.BlockProcessor.Core.PoolSupervisor, :start_link, [10]}
      },
      {Rudder.Pipeline.Spawner, name: Rudder.Pipeline.Spawner},
      {Rudder.Telemetry, name: Rudder.Telemetry},
      {Rudder.Telemetry.ReporterState, {0, 0}}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    options = [strategy: :one_for_one, name: Rudder.Supervisor]

    Supervisor.start_link(children, options)
  end
end
