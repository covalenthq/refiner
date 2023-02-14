defmodule Rudder.Telemetry.PlugReporter do
  use GenServer

  require Logger

  alias Telemetry.Metrics.{Counter, Distribution, LastValue, Sum, Summary}

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts[:metrics])
  end

  def init(metrics) do
    Process.flag(:trap_exit, true)

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

  def handle_metric(%Counter{}, _measurements, _metadata) do
    :ets.update_counter(:rudder_metrics, :counter, 1, {:counter, 0})

    Logger.info("Counter - #{inspect(:ets.lookup(:rudder_metrics, :counter))}")
  end

  def handle_metric(%LastValue{} = metric, measurements, _metadata) do
    duration = extract_measurement(metric, measurements)
    key = :last_exec_time

    :ets.insert(:rudder_metrics, {key, duration})

    Logger.info("LastValue - #{inspect(:ets.lookup(:rudder_metrics, key))}")
  end

  def handle_metric(%Sum{} = metric , measurements, _metadata) do
    duration = extract_measurement(metric, measurements)
    key = :total_exec_time

    IO.inspect(:ets.lookup(:rudder_metrics, :last_exec_time))

    total_exec_time =
      case :ets.lookup(:rudder_metrics, :last_exec_time) do
        [last_exec_time: time] -> time + duration
        _ ->
          duration
      end

      :ets.insert(:rudder_metrics, {key, total_exec_time})

    Logger.info("Sum - #{inspect(:ets.lookup(:rudder_metrics, key))}")
  end

  def handle_metric(%Summary{} = metric, measurements, _metadata) do
    duration = extract_measurement(metric, measurements)

    summary =
      case :ets.lookup(:rudder_metrics, :summary) do
        [summary: {min, max}] ->
          {
            min(min, duration),
            max(max, duration)
          }

        _ ->
          {duration, duration}
      end

    :ets.insert(:rudder_metrics, {:summary, summary})

    Logger.info "Summary - #{inspect summary}"
  end

  def handle_metric(%Distribution{} = metric, measurements, _metadata) do
    duration = extract_measurement(metric, measurements)

    update_distribution(metric.buckets, duration)

    Logger.info(
      "Distribution - #{inspect(:ets.match_object(:rudder_metrics, {{:distribution, :_}, :_}))}"
    )
  end

  defp update_distribution([], _duration) do
    key = {:distribution, "1000+"}
    :ets.update_counter(:rudder_metrics, key, 1, {key, 0})
  end

  defp update_distribution([head | _buckets], duration) when duration <= head do
    key = {:distribution, head}
    :ets.update_counter(:rudder_metrics, key, 1, {key, 0})
  end

  defp update_distribution([_head | buckets], duration) do
    update_distribution(buckets, duration)
  end

  def terminate(_, events) do
    events
    |> Enum.each(&:telemetry.detach({__MODULE__, &1, self()}))

    :ok
  end
end
