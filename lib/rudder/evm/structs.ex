defmodule Rudder.BlockProcessor.Struct do
  require Logger
  require System

  defmodule PoolState do
    defstruct [:request_queue, workers_limit: 10]
  end

  defmodule InputParams do
    @enforce_keys [:block_id]
    defstruct [:block_id, :contents, :sender, :misc]
  end

  defmodule EVMParams do
    alias Rudder.BlockProcessor.Struct.EVMParams
    @default_input_replica_path "stdin"
    @default_output_dir "./evm-out"
    @default_evm_exec_path "./plugins/evm"
    defstruct evm_exec_path: @default_evm_exec_path,
              input_replica_path: @default_input_replica_path,
              output_basedir: @default_output_dir

    def new() do
      evm_path = Application.get_env(:rudder, :evm_path)

      evm_path =
        if evm_path != nil do
          evm_path
        else
          @default_evm_exec_path
        end

      %EVMParams{evm_exec_path: evm_path}
    end
  end

  defmodule ExecResult do
    defstruct [:status, :block_id, :output_path, :misc]
  end
end
