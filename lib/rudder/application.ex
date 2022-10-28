defmodule Rudder.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      %{
        id: Rudder.BlockSpecimenDiscoverer,
        start: {Rudder.BlockSpecimenDiscoverer, :start_link, [[]]}
      },
      {Finch,
       name: Rudder.Finch,
       pools: %{
         :default => [size: 32]
       }},
      {Rudder.IPFSInteractor, name: Rudder.IPFSInteractor},
      Rudder.Avro.Client,
      {Rudder.Avro.BlockSpecimenDecoder, name: Rudder.Avro.BlockSpecimenDecoder},
      {Rudder.BlockResultUploader, name: Rudder.BlockResultUploader}
      # %{
      #   id: Rudder.BlockProcessor.Core.Server,
      #   start: {Rudder.BlockProcessor.Core.Server, :start_link, [%{request_queue: :queue.new()}]}
      # }
    ]

    Rudder.BlockProcessor.start()

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    options = [strategy: :one_for_one, name: Rudder.Supervisor]

    Supervisor.start_link(children, options)
  end
end
