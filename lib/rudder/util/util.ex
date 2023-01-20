defmodule Rudder.Util do
  def typeof(a) do
    cond do
      is_float(a) -> "float"
      is_number(a) -> "number"
      is_boolean(a) -> "boolean"
      is_atom(a) -> "atom"
      is_binary(a) -> "binary"
      is_function(a) -> "function"
      is_list(a) -> "list"
      is_tuple(a) -> "tuple"
      true -> "idunno"
    end
  end

  def get_file_paths(dir_path) do
    try do
      Path.wildcard(dir_path)
    catch
      File.Error -> raise "could not find a file at path #{dir_path}"
    end
  end

  def extract_data(log_event, signature) do
    {:ok, data} = Map.fetch(log_event, "data")
    "0x" <> data = data
    fs = ABI.FunctionSelector.decode(signature)
    ABI.decode(fs, data |> Base.decode16!(case: :lower))
  end

  def convert_to_bytes32(str) do
    Base.decode16!(str, case: :mixed)
  end
end
