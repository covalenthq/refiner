defmodule Rudder.IPFSInteractor do
  use GenServer

  alias Rudder.IPFSInteractor
  alias Multipart.Part

  def start_link(opts) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  @impl true
  def init(:ok) do
    {:ok, []}
  end

  @impl true
  def handle_call({:pin, file_path}, _from, state) do
    port = Application.get_env(:rudder, :ipfs_pinner_port)

    url = "http://localhost:#{port}/upload"

    multipart = Multipart.new() |> Multipart.add_part(Part.file_body(file_path))
    body_stream = Multipart.body_stream(multipart)
    content_length = Multipart.content_length(multipart)
    content_type = Multipart.content_type(multipart, "multipart/form-data")
    headers = [{"Content-Type", content_type}, {"Content-Length", to_string(content_length)}]

    {:ok, %Finch.Response{body: body, headers: _, status: _}} =
      Finch.build("POST", url, headers, {:stream, body_stream})
      |> Finch.request(Rudder.Finch)

    body_map = body |> Poison.decode!()

    case body_map do
      %{"error" => error} -> {:reply, {:error, error}, state}
      %{"cid" => cid} -> {:reply, {:ok, cid}, state}
    end
  end

  @impl true
  def handle_call({:fetch, cid}, _from, state) do
    port = Application.get_env(:rudder, :ipfs_pinner_port)

    {:ok, %Finch.Response{body: body, headers: _, status: _}} =
      Finch.build(:get, "http://localhost:#{port}/get?cid=#{cid}")
      |> Finch.request(Rudder.Finch, receive_timeout: 60_000_000, pool_timeout: 60_000_000)

    {:reply, body, state}
  end

  def pin(path) do
    GenServer.call(Rudder.IPFSInteractor, {:pin, path}, :infinity)
  end

  def fetch(cid) do
    GenServer.call(Rudder.IPFSInteractor, {:fetch, cid}, :infinity)
  end

  def discover_block_specimen([url | _]) do
    ["ipfs", cid] = String.split(url, "://")

    response = Rudder.IPFSInteractor.fetch(cid)
    {:ok, response}
  end
end
