defmodule Rudder.BlockProcessor.Struct do
  require System

  defmodule PoolState do
    defstruct [:request_queue, workers_limit: 10]
  end

  defmodule InputParams do
    @enforce_keys [:block_id]
    defstruct [:block_id, :contents, :sender, :misc]
  end

  defmodule ExecResult do
    defstruct [:status, :block_id, :output_path, :misc]
  end
end
