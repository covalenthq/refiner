defmodule Rudder.IPFSInteractor do
  use GenServer

  alias Multipart.Part
  alias Rudder.Events

  require Logger

  @spec start_link([
          {:debug, [:log | :statistics | :trace | {any, any}]}
          | {:hibernate_after, :infinity | non_neg_integer}
          | {:name, atom | {:global, any} | {:via, atom, any}}
          | {:spawn_opt, [:link | :monitor | {any, any}]}
          | {:timeout, :infinity | non_neg_integer}
        ]) :: :ignore | {:error, any} | {:ok, pid}
  def start_link(opts) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  @impl true
  @spec init(:ok) :: {:ok, []}
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

    resp =
      Finch.build("POST", url, headers, {:stream, body_stream})
      |> Finch.request(Rudder.Finch)

    case resp do
      {:ok, %Finch.Response{body: body, headers: _, status: _}} ->
        body_map = body |> Poison.decode!()

        end_pin_ms = System.monotonic_time(:millisecond)
        Events.ipfs_pin(end_pin_ms - start_pin_ms)

        case body_map do
          %{"error" => error} -> {:reply, {:error, error}, state}
          %{"cid" => cid} -> {:reply, {:ok, cid}, state}
        end

      {:error, %Mint.TransportError{reason: :econnrefused}} ->
        raise "connection refused: is ipfs-pinner started?"

      {:error, err} ->
        {:reply, {:error, err}, state}
    end
  end

  @impl true
  def handle_call({:fetch, cid}, _from, state) do
    start_fetch_ms = System.monotonic_time(:millisecond)

    ipfs_url = Application.get_env(:rudder, :ipfs_pinner_url)

    resp =
      Finch.build(:get, "#{ipfs_url}/get?cid=#{cid}")
      |> Finch.request(Rudder.Finch, receive_timeout: 150_000_000, pool_timeout: 150_000_000)

    case resp do
      {:ok, %Finch.Response{body: body, headers: _, status: _}} ->
        end_fetch_ms = System.monotonic_time(:millisecond)
        Events.ipfs_fetch(end_fetch_ms - start_fetch_ms)

        try do
          body_map = body |> Poison.decode!()

          case body_map do
            %{"error" => error} -> {:reply, {:error, error}, state}
            _ -> {:reply, {:ok, body}, state}
          end
        rescue
          _ -> {:reply, {:ok, body}, state}
        end

      {:error, %Mint.TransportError{reason: :econnrefused}} ->
        raise "connection refused: is ipfs-pinner started?"

      {:error, err} ->
        {:reply, {:error, err}, state}
    end
  end

  @spec pin(any) :: any
  def pin(path) do
    GenServer.call(Rudder.IPFSInteractor, {:pin, path}, :infinity)
  end

  @spec fetch(any) :: any
  def fetch(cid) do
    GenServer.call(Rudder.IPFSInteractor, {:fetch, cid}, :infinity)
  end

  @spec discover_block_specimen(nonempty_maybe_improper_list) :: {:ok, any}
  def discover_block_specimen([url | _]) do
    ["ipfs", cid] = String.split(url, "://")

    Rudder.IPFSInteractor.fetch(cid)
  end
end
