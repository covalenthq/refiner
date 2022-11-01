defmodule Rudder.Util do
  def typeof(a) do
    cond do
      is_float(a) -> "float"
      is_number(a) -> "number"
      is_atom(a) -> "atom"
      is_boolean(a) -> "boolean"
      is_binary(a) -> "binary"
      is_function(a) -> "function"
      is_list(a) -> "list"
      is_tuple(a) -> "tuple"
      true -> "idunno"
    end
  end

  def file_open(path) do
    Path.wildcard(path)
  end

  def extract_data(log_event, signature) do
    {:ok, data} = Map.fetch(log_event, "data")
    "0x" <> data = data
    fs = ABI.FunctionSelector.decode(signature)
    ABI.decode(fs, data |> Base.decode16!(case: :lower))
  end

  def get_system_arch do
    :erlang.system_info(:system_architecture)
  end

  def append_to_file(text, filepath) do
    {:ok, file} = File.open(filepath, [:append, {:delayed_write, 100, 20}])
    Enum.each(text, &IO.binwrite(file, &1))
    File.close(file)
  end
end
