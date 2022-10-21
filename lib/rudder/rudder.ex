# defmodule Rudder do
#   defp get_json(filename) do
#     with {:ok, body} <- File.read(filename) do
#       Poison.decode(body)
#     end
#   end

#   defp load_build_file(build_filename) do
#     get_json(build_filename)
#   end

#   defp get_input(formula) do
#     Map.get(formula, "input")
#   end

#   defp get_output(formula) do
#     Map.get(formula, "output")
#   end

#   defp get_rule(formula) do
#     Map.get(formula, "rule")
#   end

#   defp get_exec(formula) do
#     Map.get(formula, "exec")
#   end

#   defp get_args(formula) do
#     Map.get(formula, "args")
#   end

#   # defp async_exec(exec_file, args) do
#   #   Porcelain.spawn_shell(exec_file, args)
#   # end

#   # defp sync_exec(build_rule) do
#   #   Porcelain.shell(build_rule)
#   # end

#   defp write_output(path, result, _modes \\ []) do
#     IO.write(path, result)
#   end

#   def build_sync(build_filename) do
#     # load rules file
#     {:ok, formula} = load_build_file(build_filename)

#     IO.inspect(formula)

#     # get input, outputs and build rules
#     input = get_input(formula)
#     output = get_output(formula)
#     build_rule = get_rule(formula)

#     # exec = get_exec(formula)
#     # args = get_args(formula)

#     # get result from rule call
#     sync_exec(build_rule)

#     # async_exec(exec, args)

#     # output = get_output(formula)
#     # write_output(output, result)
#   end

#   def build_async(build_filename, args) do
#     # load rules file
#     {:ok, formula} = load_build_file(build_filename)

#     instream = SocketStream.new('example.com', 80)
#     opts = [in: instream, out: :stream]

#     input = get_input(formula)
#     output = get_output(formula)
#     build_rule = get_rule(formula)

#     # proc = %Proc{out: outstream} = async_exec(build_rule, args)

#     # Enum.into(outstream, IO.stream(:stdio, :line))
#     # # => false
#     # Proc.alive?(proc)
#   end

# end
