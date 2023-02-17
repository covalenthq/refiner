defmodule Rudder.Journal do
  @moduledoc """
  A journal for recording work done by the processing engine. Before the engine starts processing, the work item, identified by some <b>id</b>
  is "start"-ed. When the processing is done, the work item is either "commit"-ed or "abort"-ed.
  """
  use GenServer

  alias Rudder.Events
  require Logger
  require Application

  @spec start_link([...]) :: :ignore | {:error, any} | {:ok, pid}
  def start_link([journal_path | opts]) do
    GenServer.start_link(__MODULE__, journal_path, opts)
  end

  @impl true
  def init(journal_path) do
    work_items_log = Path.join(journal_path, "worklog.etf")
    block_height_log = Path.join(journal_path, "block_height.etf")

    {:ok,
     {ETFs.DebugFile.open_async(:work_items_processor_journal, work_items_log),
      ETFs.DebugFile.open_async(:block_height_processor_journal, block_height_log)}}
  end

  @impl true
  def handle_call({:blockh, :fetch}, _from, {_workitem_log, blockh_log} = state) do
    start_journal_ms = System.monotonic_time(:millisecond)
    Logger.info("getting the last unprocessed block height")

    task =
      Task.async(fn ->
        ETFs.DebugFile.stream!(blockh_log.disk_log_name, blockh_log.path)
        |> Enum.reduce({MapSet.new(), 0}, fn elem, {running_set, max_height} ->
          case elem do
            {:start, height} ->
              set = MapSet.put(running_set, height)
              max_height = max(max_height, height)
              {set, max_height}

            {:commit, height} ->
              set = MapSet.delete(running_set, height)
              max_height = max(max_height, height)
              {set, max_height}
          end
        end)
      end)

    {result, max_height} = Task.await(task)
    Events.journal_fetch_last(System.monotonic_time(:millisecond) - start_journal_ms)
    {:reply, {:ok, Enum.min(result, &<=/2, fn -> max_height + 1 end)}, state}
  end

  @doc """
  returns a list of ids which are in the given status stage
  """
  @impl true
  def handle_call({:workitem, :fetch, status}, _from, {workitem_log, _blockh_log} = state) do
    start_journal_ms = System.monotonic_time(:millisecond)
    Logger.info("getting ids with status=#{status}")

    ## filter function for Enum.reduce/3
    filter_fn =
      cond do
        status in [:commit, :abort, :skip] ->
          fn elem, accumulator ->
            case elem do
              {^status, id} -> MapSet.put(accumulator, id)
              {_, _} -> accumulator
            end
          end

        status == :discover ->
          fn elem, accumulator ->
            case elem do
              {^status, id} -> MapSet.put(accumulator, id)
              {_, id} -> MapSet.delete(accumulator, id)
            end
          end
      end

    task =
      Task.async(fn ->
        ETFs.DebugFile.stream!(workitem_log.disk_log_name, workitem_log.path)
        |> Enum.reduce(MapSet.new(), filter_fn)
        |> Enum.to_list()
      end)

    result = Task.await(task)
    Events.journal_fetch_items(System.monotonic_time(:millisecond) - start_journal_ms)
    {:reply, {:ok, result}, state}
  end

  @impl true
  def handle_call({:workitem, status, id}, _from, {workitem_log, blockh_log}) do
    workitem_log = ETFs.DebugFile.log_term!(workitem_log, {status, id})
    {:reply, :ok, {workitem_log, blockh_log}}
  end

  @impl true
  def handle_call({:blockh, status, height}, _from, {workitem_log, blockh_log}) do
    blockh_log = ETFs.DebugFile.log_term!(blockh_log, {status, height})
    {:reply, :ok, {workitem_log, blockh_log}}
  end

  @impl true
  def terminate(reason, {workitem_log, blockh_log}) do
    Logger.info("journal terminated, reason: #{inspect(reason)}")
    ETFs.DebugFile.close(workitem_log)
    ETFs.DebugFile.close(blockh_log)
  end

  @spec items_with_status(any) :: any
  @doc """
  returns items which are on given status
  status: :discover, :skip, :commit, :abort
  """
  def items_with_status(status) do
    if status in [:commit, :abort, :discover, :skip] do
      {:ok, items} = GenServer.call(Rudder.Journal, {:workitem, :fetch, status}, :infinity)
      items
    else
      Logger.info("status not supported provided #{status}")
      {:error, "wrong status"}
    end
  end

  @spec last_started_block :: any
  @doc """
  returns the last block which was "started" but not "commit"/"aborted".
  Returns 1 + last_process_block_height in case no such block exists
  """
  def last_started_block() do
    GenServer.call(Rudder.Journal, {:blockh, :fetch})
  end

  # ethereum block ids status logging

  @spec discover(any) :: any
  def discover(id) do
    GenServer.call(Rudder.Journal, {:workitem, :discover, id}, 500_000)
  end

  @spec commit(any) :: any
  def commit(id) do
    GenServer.call(Rudder.Journal, {:workitem, :commit, id}, 500_000)
  end

  @spec abort(any) :: any
  def abort(id) do
    GenServer.call(Rudder.Journal, {:workitem, :abort, id}, 500_000)
  end

  @spec skip(any) :: any
  def skip(id) do
    GenServer.call(Rudder.Journal, {:workitem, :skip, id}, 500_000)
  end

  # moonbeam block_height status logging APIs
  @spec block_height_started(any) :: any
  def block_height_started(height) do
    GenServer.call(Rudder.Journal, {:blockh, :start, height}, 500_000)
  end

  @spec block_height_committed(any) :: any
  def block_height_committed(height) do
    GenServer.call(Rudder.Journal, {:blockh, :commit, height}, 500_000)
  end
end
