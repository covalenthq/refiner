defmodule Refiner.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  @spec start(any, any) :: {:error, any} | {:ok, pid}
  def start(_type, _args) do
    children = [
      {Finch,
       name: Refiner.Finch,
       pools: %{
         :default => [size: 32]
       }},
      {Refiner.IPFSInteractor, name: Refiner.IPFSInteractor},
      {Refiner.Journal, [Application.get_env(:refiner, :journal_path), name: Refiner.Journal]},
      Refiner.Avro.Client,
      {Refiner.Avro.BlockSpecimen, name: Refiner.Avro.BlockSpecimen},
      {Refiner.BlockResultUploader, name: Refiner.BlockResultUploader},
      {Refiner.BlockProcessor,
       [Application.get_env(:refiner, :evm_server_url), name: Refiner.BlockProcessor]},
      {Refiner.Pipeline.Spawner, name: Refiner.Pipeline.Spawner},
      {Refiner.Telemetry, name: Refiner.Telemetry}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    options = [
      strategy: :one_for_one,
      name: Refiner.Supervisor,
      max_restarts: 3,
      max_seconds: 1200
    ]

    Supervisor.start_link(children, options)
  end
end
