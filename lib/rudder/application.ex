defmodule Rudder.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      %{
        id: Rudder.SourceDiscovery,
        start: {Rudder.SourceDiscovery, :start_link, [[]]}
      },
      {Finch,
       name: Rudder.Finch,
       pools: %{
         :default => [size: 32]
       }},
      Rudder.Avro.Client,
      {Rudder.Avro.BlockSpecimenDecoder, name: Rudder.Avro.BlockSpecimenDecoder},
      {Rudder.BlockResultUploader, name: Rudder.BlockResultUploader}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Rudder.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
