defmodule Rudder.BlockProcessor.Struct do
  defmodule PoolState do
    defstruct [:request_queue, workers_limit: 10]
  end

  defmodule InputParams do
    @enforce_keys [:block_id]
    defstruct [:block_id, :contents, :sender, :misc]
  end

  defmodule EVMParams do
    @default_input_replica_path "stdin"
    @default_output_dir "./evm-out"
    defstruct [
      :evm_exec_path,
      input_replica_path: @default_input_replica_path,
      output_basedir: @default_output_dir
    ]
  end

  defmodule ExecResult do
    defstruct [:status, :block_id, :output_path, :misc]
  end
end
