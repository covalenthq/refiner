defmodule Rudder.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  @spec start(any, any) :: {:error, any} | {:ok, pid}
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
      {Rudder.BlockProcessor,
       [Application.get_env(:rudder, :evm_server_url), name: Rudder.BlockProcessor]},
      {Rudder.Pipeline.Spawner, name: Rudder.Pipeline.Spawner},
      {Rudder.Telemetry, name: Rudder.Telemetry}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    options = [strategy: :one_for_one, name: Rudder.Supervisor]

    Supervisor.start_link(children, options)
  end
end
