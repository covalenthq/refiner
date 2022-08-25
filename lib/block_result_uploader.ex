defmodule Rudder.BlockResultUploader do
  use GenServer

  def child_spec(_) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, []},
      type: :worker
    }
  end

  def start_link() do
    GenServer.start_link(__MODULE__, fn -> [] end, name: :block_result_uploader)
  end

  @impl true
  def init(pinner) do
    {:ok, pinner}
  end

  @impl true
  def handle_cast({:pin, file_path}, state) do
    %HTTPoison.Response{
      body: x,
      headers: _,
      request: _,
      request_url: _,
      status_code: y
      } = HTTPoison.get!("http://localhost:3001/time?address=#{file_path}")
    {:noreply, [{y, x} | state]}
  end

  @impl true
  def handle_call(:pop, _from, state) do
    {:reply, state, state}
  end



end
