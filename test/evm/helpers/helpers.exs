defmodule TestHelper do
  defmodule SupervisorUtils do
    ## This function is added in ExUnit in elixir 1.14.0, remove this once we migrate.
    def start_link_supervised!(child_spec_or_module, opts \\ []) do
      pid = ExUnit.Callbacks.start_supervised!(child_spec_or_module, opts)
      Process.link(pid)
      pid
    end
  end
end
