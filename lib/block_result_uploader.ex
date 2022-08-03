# defmodule Rudder.BlockResultUploader do
#     def child_spec(_) do
#       %{
#         id: __MODULE__,
#         start: {__MODULE__, :start_link, []},
#         type: :worker
#       }
#     end

#     def start_link() do
#       Agent.start_link(fn -> [] end, name: :block_result_uploader)
#     end
#   end
