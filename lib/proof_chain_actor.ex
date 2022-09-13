defmodule Rudder.ProofChainActor do
  def child_spec(_) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, []},
      type: :supervisor
    }
  end

  def start_link() do
    children = [
      {Rudder.BlockResultUploader, []}
    ]

    Supervisor.start_link(children, name: :proof_chain_actor, strategy: :one_for_one)
  end
end
