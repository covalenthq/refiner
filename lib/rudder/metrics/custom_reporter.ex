defmodule Rudder.Telemetry.CustomReporter do
  use GenServer

  require Logger

  alias Telemetry.Metrics.{Counter, Distribution, LastValue, Sum, Summary}

  @spec start_link(nil | maybe_improper_list | map) :: :ignore | {:error, any} | {:ok, pid}
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts[:metrics])
  end

  def init(metrics) do
    Process.flag(:trap_exit, true)

    # all event metrics
    :ets.new(:emit_metrics, [:named_table, :public, :set, {:write_concurrency, true}])
    # ipfs events (instrumented)
    :ets.new(:ipfs_metrics, [:named_table, :public, :set, {:write_concurrency, true}])
    # bsp events (instrumented)
    :ets.new(:bsp_metrics, [:named_table, :public, :set, {:write_concurrency, true}])
    # brp events (instrumented)
    :ets.new(:brp_metrics, [:named_table, :public, :set, {:write_concurrency, true}])
    # application wide events (instrumented)
    :ets.new(:rudder_metrics, [:named_table, :public, :set, {:write_concurrency, true}])

    groups = Enum.group_by(metrics, & &1.event_name)

    for {event, metrics} <- groups do
      id = {__MODULE__, event, self()}
      :telemetry.attach(id, event, &__MODULE__.handle_event/4, metrics)
    end

    {:ok, Map.keys(groups)}
  end

  def handle_event(_event_name, measurements, metadata, metrics) do
    metrics
    |> Enum.map(&handle_metric(&1, measurements, metadata))
  end

  defp extract_measurement(metric, measurements) do
    case metric.measurement do
      fun when is_function(fun, 1) ->
        fun.(measurements)

      key ->
        measurements[key]
    end
  end

  @doc """
  Telemetry.Metrics.Counter: Used to keep a running count of the number of events.
  Telemetry.Metrics.Sum: Used to track the sum total of specific measurements.
  Telemetry.Metrics.LastValue: Use this metric to hold the measurement of the most recent event.
  Telemetry.Metrics.Summary: Used to track and calculate statistics of the selected measurement such as min/max, average, percentile, etc.
  Telemetry.Metrics.Distribution: Used to group event measurements into buckets
  """
  @spec handle_metric(
          %{
            :__struct__ =>
              Telemetry.Metrics.Counter
              | Telemetry.Metrics.Distribution
              | Telemetry.Metrics.LastValue
              | Telemetry.Metrics.Sum
              | Telemetry.Metrics.Summary,
            optional(any) => any
          },
          any,
          any
        ) :: :ok
  def handle_metric(%Counter{}, _measurements, metadata) do
    table_name = String.to_atom(metadata.table)
    event_name = String.to_atom(metadata.operation)

    :ets.update_counter(table_name, event_name, 1, {event_name, 0})

    Logger.info("Counter for #{table_name} - #{inspect(:ets.lookup(table_name, event_name))}")
  end

  def handle_metric(%LastValue{} = metric, measurements, metadata) do
    duration = extract_measurement(metric, measurements)
    table_name = String.to_atom(metadata.table)
    event_name = String.to_atom(metadata.operation)
    last_exec_time_key = :"#{event_name}#{:_last_exec_time}"

    :ets.insert(table_name, {last_exec_time_key, duration})

    Logger.info(
      "LastValue for #{table_name} - #{inspect(:ets.lookup(table_name, last_exec_time_key))}"
    )
  end

  def handle_metric(%Sum{} = metric, measurements, metadata) do
    duration = extract_measurement(metric, measurements)
    table_name = String.to_atom(metadata.table)
    event_name = String.to_atom(metadata.operation)
    total_exec_time_key = :"#{event_name}#{:_total_exec_time}"

    total_exec_time =
      case Keyword.fetch(:ets.lookup(table_name, total_exec_time_key), total_exec_time_key) do
        {:ok, time} ->
          time + duration

        :error ->
          duration
      end

    :ets.insert(table_name, {total_exec_time_key, total_exec_time})

    Logger.info(
      "Sum for #{table_name} - #{inspect(:ets.lookup(table_name, total_exec_time_key))}"
    )
  end

  def handle_metric(%Summary{} = metric, measurements, metadata) do
    duration = extract_measurement(metric, measurements)
    table_name = String.to_atom(metadata.table)
    event_name = String.to_atom(metadata.operation)
    summary_key = :"#{event_name}#{:_summary}"

    summary =
      case Keyword.fetch(:ets.lookup(table_name, summary_key), summary_key) do
        {:ok, {min, max}} ->
          {
            min(min, duration),
            max(max, duration)
          }

        :error ->
          {duration, duration}
      end

    :ets.insert(table_name, {summary_key, summary})

    Logger.info("Summary for #{table_name}  - #{inspect(summary)}")
  end

  def handle_metric(%Distribution{} = metric, measurements, metadata) do
    duration = extract_measurement(metric, measurements)
    table_name = String.to_atom(metadata.table)
    event_name = String.to_atom(metadata.operation)
    distribution_key = :"#{event_name}#{:_distribution}"

    update_distribution(metric.buckets, duration, table_name, distribution_key)

    Logger.info(
      "Distribution for #{table_name} - #{inspect(:ets.match_object(table_name, {{distribution_key, :_}, :_}))}"
    )
  end

  defp update_distribution([], _duration, table_name, key_name) do
    key = {key_name, "1000+"}
    :ets.update_counter(table_name, key, 1, {key, 0})
  end

  defp update_distribution([head | _buckets], duration, table_name, key_name)
       when duration <= head do
    key = {key_name, head}
    :ets.update_counter(table_name, key, 1, {key, 0})
  end

  defp update_distribution([_head | buckets], duration, table_name, key_name) do
    update_distribution(buckets, duration, table_name, key_name)
  end

  def terminate(_, events) do
    events
    |> Enum.each(&:telemetry.detach({__MODULE__, &1, self()}))

    :ok
  end
end
