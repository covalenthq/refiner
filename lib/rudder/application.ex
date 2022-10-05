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
      }
      %{
        id: Rudder.Avro.DecodeBlockSpecimen,
        start: {Rudder.Avro.DecodeBlockSpecimen, :start_link, [[]]}
      }
      Rudder.Avro.Client
      },
      {Finch,
       name: Rudder.Finch,
       pools: %{
         :default => [size: 32]
       }}
      # Starts a worker by calling: Rudder.Worker.start_link(arg)
      # {Rudder.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Rudder.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
