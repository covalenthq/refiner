defmodule Rudder.Journal do
  @moduledoc """
  A journal for recording work done by the processing engine. Before the engine starts processing, the work item, identified by some <b>id</b>
  is "start"-ed. When the processing is done, the work item is either "commit"-ed or "abort"-ed.
  """
  use GenServer

  require Logger
  require Application

  def start_link([journal_path | opts]) do
    GenServer.start_link(__MODULE__, journal_path, opts)
  end

  @impl true
  def init(journal_path) do
    {:ok, ETFs.DebugFile.open_async(:processor_journal, journal_path)}
  end

  @doc """
  returns a list of ids which are in the given status stage
  """
  @impl true
  def handle_call({:fetch, status}, _from, state) do
    Logger.info("getting ids with status=#{status}")

    ## filter function for Enum.reduce/3
    filter_fn =
      cond do
        status in [:commit, :abort] ->
          fn elem, accumulator ->
            case elem do
              {^status, id} -> MapSet.put(accumulator, id)
              {_, _} -> accumulator
            end
          end

        status == :awarded ->
          fn elem, accumulator ->
            case elem do
              {^status, id} ->
                MapSet.put(accumulator, id)

              {finalizing_status, id} when finalizing_status in [:commit, :abort] ->
                MapSet.delete(accumulator, id)

              {_, _} ->
                accumulator
            end
          end

        status == :discovered ->
          fn elem, accumulator ->
            case elem do
              {^status, id} -> MapSet.put(accumulator, id)
              {_, id} -> MapSet.delete(accumulator, id)
            end
          end
      end

    result =
      ETFs.DebugFile.stream!(state)
      |> Enum.reduce(MapSet.new(), filter_fn)
      |> Enum.to_list()

    {:reply, {:ok, result}, state}
  end

  @impl true
  def handle_call({status, id}, _from, state) do
    ETFs.DebugFile.log_term!(state, {status, id})
    {:reply, :ok, state}
  end

  @impl true
  def terminate(reason, state) do
    Logger.info("journal terminated, reason: #{inspect(reason)}")
    ETFs.DebugFile.close(state)
  end

  @doc """
  returns items which are on given status
  status: :discovered, :awarded, :commit, :abort
  """
  def items_with_status(status) do
    cond do
      status in [:awarded, :commit, :abort, :discovered] ->
        {:ok, items} = GenServer.call(Rudder.Journal, {:fetch, status}, :infinity)
        items

      true ->
        Logger.info("wrong status provided #{status}")
        {:error, "wrong status"}
    end
  end

  def discovered(id) do
    GenServer.call(Rudder.Journal, {:discovered, id}, 5_00_000)
  end

  def awarded(id) do
    GenServer.call(Rudder.Journal, {:awarded, id}, 5_00_000)
  end

  def commit(id) do
    GenServer.call(Rudder.Journal, {:commit, id}, 5_00_000)
  end

  def abort(id) do
    GenServer.call(Rudder.Journal, {:abort, id}, 5_00_000)
  end
end
