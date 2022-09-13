defmodule Rudder.RPC.DecodeError do
  defexception [:message]

  def exception(error) do
    msg = "Error while decoding RPC response: #{inspect(error)}"
    %__MODULE__{message: msg}
  end
end

defmodule Rudder.RPCError do
  defexception [:message]

  def exception(error) do
    msg = "RPC error: #{inspect(error)}"
    %__MODULE__{message: msg}
  end
end

defmodule Rudder.RPC.Semaphore do
  use GenServer

  def start_link(_) do
    GenServer.start_link(__MODULE__, nil, [])
  end

  def init(_) do
    {:ok, nil}
  end
end
