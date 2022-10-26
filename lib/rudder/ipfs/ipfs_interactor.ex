defmodule Rudder.IPFSInteractor do
  use GenServer

  def start_link(opts) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  @impl true
  def init(:ok) do
    {:ok, []}
  end

  @impl true
  def handle_call({:pin, file_path}, _from, state) do
    port = Application.get_env(:ipfs_pinner, :port)
    url = "http://localhost:#{port}/upload?filePath=#{file_path}"

    {:ok, %Finch.Response{body: body, headers: _, status: _}} =
      Finch.build(
        :get,
        url
      )
      |> Finch.request(Rudder.Finch)

    body_map = body |> Poison.decode!()

    case body_map do
      %{"error" => error} -> {:reply, {:error, error}, state}
      %{"cid" => cid} -> {:reply, {:ok, cid}, state}
    end
  end

  @impl true
  def handle_call({:fetch, cid}, _from, state) do
    port = Application.get_env(:ipfs_pinner, :port)

    {status, data} =
      Finch.build(:get, "http://localhost:#{port}/get?cid=#{cid}")
      |> Finch.request(Rudder.Finch, receive_timeout: 60_000, pool_timeout: 60_000)

    {:reply, {status, data}, state}
  end

  def pin(path) do
    GenServer.call(Rudder.IPFSInteractor, {:pin, path}, :infinity)
  end

  def fetch(cid) do
    GenServer.call(Rudder.IPFSInteractor, {:fetch, cid}, :infinity)
  end
end
