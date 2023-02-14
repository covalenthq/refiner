defmodule Rudder.IPFSInteractor do
  use GenServer

  alias Multipart.Part
  alias Rudder.Events

  def start_link(opts) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  @impl true
  def init(:ok) do
    {:ok, []}
  end

  @impl true
  def handle_call({:pin, file_path}, _from, state) do
    start_pin_ms = System.monotonic_time(:millisecond)

    ipfs_url = Application.get_env(:rudder, :ipfs_pinner_url)
    url = "#{ipfs_url}/upload"

    multipart = Multipart.new() |> Multipart.add_part(Part.file_body(file_path))
    body_stream = Multipart.body_stream(multipart)
    content_length = Multipart.content_length(multipart)
    content_type = Multipart.content_type(multipart, "multipart/form-data")
    headers = [{"Content-Type", content_type}, {"Content-Length", to_string(content_length)}]

    {:ok, %Finch.Response{body: body, headers: _, status: _}} =
      Finch.build("POST", url, headers, {:stream, body_stream})
      |> Finch.request(Rudder.Finch)

    body_map = body |> Poison.decode!()

    end_pin_ms = System.monotonic_time(:millisecond)
    Events.ipfs_pin(end_pin_ms - start_pin_ms)

    case body_map do
      %{"error" => error} -> {:reply, {:error, error}, state}
      %{"cid" => cid} -> {:reply, {:ok, cid}, state}
    end
  end

  @impl true
  def handle_call({:fetch, cid}, _from, state) do
    start_fetch_ms = System.monotonic_time(:millisecond)

    ipfs_url = Application.get_env(:rudder, :ipfs_pinner_url)
    url = "#{ipfs_url}"

    {:ok, %Finch.Response{body: body, headers: _, status: _}} =
      Finch.build(:get, "#{url}/get?cid=#{cid}")
      |> Finch.request(Rudder.Finch, receive_timeout: 60_000_000, pool_timeout: 60_000_000)

    end_fetch_ms = System.monotonic_time(:millisecond)
    Events.ipfs_fetch(end_fetch_ms - start_fetch_ms)

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
