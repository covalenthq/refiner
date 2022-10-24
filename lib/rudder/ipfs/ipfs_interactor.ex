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

    {:ok, %Finch.Response{body: body, headers: _, status: _}} =
      Finch.build(
        :get,
        "http://localhost:#{port}/pin?filePath=#{file_path}"
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
    {err, data} =
      Finch.build(
        :get,
        "https://dweb.link/ipfs/#{cid}"
      )
      |> Finch.request(Rudder.Finch, receive_timeout: 50_000)

    {:reply, {err, data}, state}
  end

  def pin(path) do
    GenServer.call(Rudder.IPFSInteractor, {:pin, path})
  end

  def fetch(cid) do
    GenServer.call(Rudder.IPFSInteractor, {:fetch, cid})
  end
end
