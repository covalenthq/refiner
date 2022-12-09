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
    work_items_log = Path.join(journal_path, "worklog.etf")
    block_height_log = Path.join(journal_path, "block_height.etf")

    {:ok,
     {ETFs.DebugFile.open_async(:processor_journal, work_items_log),
      ETFs.DebugFile.open_async(:processor_journal, block_height_log)}}
  end

  @impl true
  def handle_call({:blockh, :fetch}, _from, {_workitem_log, blockh_log} = state) do
    Logger.info("getting the last unprocessed block height")

    {result, max_height} =
      ETFs.DebugFile.stream!(blockh_log)
      |> Enum.reduce({MapSet.new(), -1}, fn elem, {running_set, max_height} ->
        case elem do
          {:started, height} ->
            set = MapSet.put(running_set, height)
            max_height = max(max_height, height)
            {set, max_height}

          {_, height} ->
            set = MapSet.delete(running_set, height)
            max_height = max(max_height, height)
            {set, max_height}
        end
      end)

    {:reply, {:ok, Enum.min(result, &<=/2, fn -> max_height + 1 end)}, state}
  end

  @doc """
  returns a list of ids which are in the given status stage
  """
  @impl true
  def handle_call({:workitem, :fetch, status}, _from, {workitem_log, _blockh_log} = state) do
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
      ETFs.DebugFile.stream!(workitem_log)
      |> Enum.reduce(MapSet.new(), filter_fn)
      |> Enum.to_list()

    {:reply, {:ok, result}, state}
  end

  @impl true
  def handle_call({:workitem, status, id}, _from, {workitem_log, _blockh_log} = state) do
    ETFs.DebugFile.log_term!(workitem_log, {status, id})
    {:reply, :ok, state}
  end

  @impl true
  def handle_call({:blockh, status, height}, _from, {_workitem_log, blockh_log} = state) do
    ETFs.DebugFile.log_term!(blockh_log, {status, height})
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
        {:ok, items} = GenServer.call(Rudder.Journal, {:workitem, :fetch, status}, :infinity)
        items

      true ->
        Logger.info("status not supported provided #{status}")
        {:error, "wrong status"}
    end
  end

  @doc """
  returns the last block which was "started" but not "committed"/"aborted".
  Returns 1 + last_process_block_height in case no such block exists
  """
  def last_started_block() do
    GenServer.call(Rudder.Journal, {:blockh, :fetch})
  end

  def discovered(id) do
    GenServer.call(Rudder.Journal, {:workitem, :discovered, id}, 5_00_000)
  end

  def awarded(id) do
    GenServer.call(Rudder.Journal, {:workitem, :awarded, id}, 5_00_000)
  end

  def commit(id) do
    GenServer.call(Rudder.Journal, {:workitem, :commit, id}, 5_00_000)
  end

  def abort(id) do
    GenServer.call(Rudder.Journal, {:workitem, :abort, id}, 5_00_000)
  end

  def block_height_started(height) do
    GenServer.call(Rudder.Journal, {:blockh, :started, height}, 5_00_000)
  end

  def block_height_committed(height) do
    GenServer.call(Rudder.Journal, {:blockh, :committed, height}, 5_00_000)
  end

  def block_height_aborted(height) do
    GenServer.call(Rudder.Journal, {:blockh, :aborted, height}, 5_00_000)
  end
end
