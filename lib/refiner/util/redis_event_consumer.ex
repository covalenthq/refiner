defmodule Refiner.RedisEventConsumer do
  # This is required so that `A` knows how to start and restart this module
  # def child_spec(_) do
  #   %{
  #     id: __MODULE__,
  #     start: {__MODULE__, :start_link, []},
  #     type: :worker
  #   }
  # end

  # def start_link() do
  #   Agent.start_link(fn -> [] end, name: :redis_event_consumer)
  # end
  use Broadway

  def start_link(_opts) do
    Broadway.start_link(__MODULE__,
      name: __MODULE__,
      producers: [
        default: [
          module: {
            OffBroadway.Redis.Producer,
            redis_instance: :some_redis_instance,
            list_name: "some_list",
            working_list_name: "some_list_processing"
          }
        ]
      ]
    )
  end
end
