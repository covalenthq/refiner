defmodule Rudder.Application do
  use Application

  def start(_type, _args) do
    children = [
      %{
        id: Rudder.SourceDiscovery,
        start: {Rudder.SourceDiscovery, :start_link, [[]]}
      },
      {Rudder.EventListener, []}
    ]

    opts = [strategy: :one_for_one, name: ContractObserver.Supervisor]
    Supervisor.start_link(children, opts)
  end

end
