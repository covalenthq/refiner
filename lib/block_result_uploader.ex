defmodule Rudder.BlockResultUploader do
  use GenServer

  def start_link(opts) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  @impl true
  def init(:ok) do
    {:ok, []}
  end

  @impl true
  def handle_cast({:pin, file_path}, state) do
    x =
      Finch.build(:get, "http://localhost:3000/pin?address=#{file_path}")
      |> Finch.request(Rudder.Finch)

    {:ok, %Finch.Response{body: y, headers: _, status: _}} = x
    # state is the latest cid if there was no error
    {:noreply, y}
  end

  @impl true
  def handle_call(:lookup, _from, state) do
    {:reply, state, state}
  end

  # client API

  def lookup() do
    GenServer.call(Rudder.BlockResultUploader, :lookup)
  end

  def pin(path) do
    GenServer.cast(Rudder.BlockResultUploader, {:pin, path})
  end

  # def check() do
  #   cid = "QmS21GuXiRMvJKHos4ZkEmQDmRBqRaF5tQS2CQCu2ne9sY"

  #   x = Finch.build(:get, "https://dweb.link/ipfs/#{cid}")
  #   |> Finch.request(Rudder.Finch, receive_timeout: 50_000)
  #   x
  # end
end
