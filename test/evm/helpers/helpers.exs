defmodule TestHelper do
  defmodule EVMInputGenerator do
    def get_evm_path(is_with_exit? \\ false) do
      case is_with_exit? do
        false -> "test/evm/evm"
        true -> "test/evm/evm-with-exit12"
      end
    end
  end

  defmodule SupervisorUtils do
    ## This function is added in ExUnit in elixir 1.14.0, remove this once we migrate.
    def start_link_supervised!(child_spec_or_module, opts \\ []) do
      pid = ExUnit.Callbacks.start_supervised!(child_spec_or_module, opts)
      Process.link(pid)
      pid
    end
  end
end
