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
    %HTTPoison.Response{
      body: x,
      headers: _,
      request: _,
      request_url: _,
      status_code: y
    } = HTTPoison.get!("http://localhost:3000/pin?address=#{file_path}")

    {:noreply, [{y, x} | state]}
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
end
