defmodule Rudder.BlockProcessor.Server do
  use GenServer
  require Logger
  alias Rudder.BlockProcessor.Struct
  alias Multipart.Part

  def start_link(opts) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  @impl true
  def init(:ok) do
    {:ok, []}
  end

  @impl true
  def handle_call({:process, block_specimen_content}, _from, state) do
    evm_server_url = Application.get_env(:rudder, :evm_server_url)
    url = "#{evm_server_url}/process"

    # multipart =
    #   Multipart.new()
    #   |> Multipart.add_part(Part.binary_body("first body"))
    #   |> Multipart.add_part(Part.binary_body("second body", [{"content-type", "text/plain"}]))
    #   |> Multipart.add_part(Part.binary_body("<p>third body</p>", [{"content-type", "text/html"}]))

    # body_stream = Multipart.body_stream(multipart)
    # content_length = Multipart.content_length(multipart)
    # content_type = Multipart.content_type(multipart, "multipart/mixed")

    # headers = [{"Content-Type", content_type}, {"Content-Length", to_string(content_length)}]

    # Finch.build("POST", "https://example.org/", headers, {:stream, body_stream})
    # |> Finch.request(MyFinch)

    multipart = Multipart.new() |> Multipart.add_part(Part.binary_body(block_specimen_content))
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
      block_result -> {:reply, {:ok, block_result}, state}
    end
  end

  def sync_queue(%Rudder.BlockSpecimen{} = block_specimen) do
    Logger.info("submitting #{block_specimen.block_height} to evm plugin...")
    GenServer.call(Rudder.BlockProcessor.Server, {:process, block_specimen.contents}, :infinity)
  end

  @impl true
  def terminate(reason, _state) do
    Logger.info("terminating blockprocessor.server: #{reason}")
  end
end
