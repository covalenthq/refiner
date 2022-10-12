defmodule Rudder.IPFSInteractor do
  use GenServer

  def start_link(opts) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  @impl true
  def init(:ok) do
    {:ok, []}
  end

  # @impl true
  # def handle_cast({:pin, file_path}, _state) do
  #   x =
  #     Finch.build(:get, "http://localhost:3000/pin?address=#{file_path}")
  #     |> Finch.request(Rudder.Finch)

  #   {:ok, %Finch.Response{body: y, headers: _, status: _}} = x
  #   # state is the latest cid if there was no error
  #   {:noreply, y}
  # end

  @impl true
  def handle_call({:pin, file_path}, _from, state) do
    {:ok, %Finch.Response{body: cid, headers: _, status: _}} =
      Finch.build(:get, "http://localhost:3000/pin?address=#{file_path}")
    |> Finch.request(Rudder.Finch)
    
    {:reply, {:ok, cid}, state}
  end


  @impl true
  def handle_call({:fetch, cid}, _from, state) do
    {err, data} =
      Finch.build(:get, "https://dweb.link/ipfs/#{cid}")
      |> Finch.request(Rudder.Finch, receive_timeout: 50_000)

    {:reply, {err, data}, state}
  end

  def pin(path) do
    GenServer.call(Rudder.IPFSInteractor, {:pin, path})
  end

  def fetch(cid) do
    GenServer.call(Rudder.IPFSInteractor, {:fetch, cid})
  end

  # @impl true
  # def handle_call(:lookup, _from, state) do
  #   {:reply, state, state}
  # end

  # client API

  # def lookup() do
  #   GenServer.call(Rudder.IPFSInteractor, :lookup)
  # end


end
