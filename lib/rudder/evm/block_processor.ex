defmodule Rudder.BlockProcessor do
  use GenServer
  require Logger
  alias Multipart.Part
  alias Rudder.Events

  def start_link([evm_server_url | opts]) do
    GenServer.start_link(__MODULE__, evm_server_url, opts)
  end

  @impl true
  def init(evm_server_url) do
    {:ok, "#{evm_server_url}/process"}
  end

  @impl true
  def handle_call({:process, block_specimen_content}, _from, state) do
    evm_server_url = state
    multipart = Multipart.new() |> Multipart.add_part(Part.binary_body(block_specimen_content))
    body_stream = Multipart.body_stream(multipart)
    content_length = Multipart.content_length(multipart)
    content_type = Multipart.content_type(multipart, "multipart/form-data")
    headers = [{"Content-Type", content_type}, {"Content-Length", to_string(content_length)}]

    case(
      Finch.build("POST", evm_server_url, headers, {:stream, body_stream})
      |> Finch.request(Rudder.Finch)
    ) do
      {:ok, %Finch.Response{body: body, headers: headers, status: status}} ->
        case body |> Poison.decode() do
          {:ok, %{"error" => error}} ->
            {:reply, {:error, error}, state}

          {:ok, _} ->
            {:reply, {:ok, body}, state}

          # parse failure
          {:error, errormsg} ->
            Logger.error("parse failure in blockprocessor: #{inspect(errormsg)}")

            Logger.error(
              "the body is: #{inspect(body)}, and headers: #{inspect(headers)}, and status: #{inspect(status)}"
            )

            {:reply, {:error, errormsg}, state}
        end

      {:error, %Mint.TransportError{reason: :econnrefused}} ->
        raise "connection refused: is evm-server started?"

      {:error, errormsg} ->
        Logger.error("error in blockprocessor: #{inspect(errormsg)}")
        {:reply, {:error, errormsg}, state}
    end
  end

  def sync_queue(%Rudder.BlockSpecimen{} = block_specimen) do
    Logger.info("submitting #{block_specimen.block_height} to evm http server...")

    start_execute_ms = System.monotonic_time(:millisecond)

    case GenServer.call(Rudder.BlockProcessor, {:process, block_specimen.contents}, 60_000) do
      {:ok, block_result} ->
        block_result_path = Briefly.create!()
        File.write!(block_result_path, block_result)
        Logger.info("writing block result into #{inspect(block_result_path)}")
        Events.bsp_execute(System.monotonic_time(:millisecond) - start_execute_ms)
        {:ok, block_result_path}

      {:error, errormsg} ->
        Logger.info(
          "error in executing #{block_specimen.block_height} specimen: #{inspect(errormsg)}"
        )

        {:error, errormsg}
    end
  end

  @impl true
  def terminate(reason, _state) do
    Logger.info("terminating blockprocessor: #{inspect(reason)}")
  end
end
