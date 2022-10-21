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

  def extract_data(block_data, signature) do
    {:ok, data} = Map.fetch(block_data, "data")
    "0x" <> data = data
    fs = ABI.FunctionSelector.decode(signature)
    ABI.decode(fs, data |> Base.decode16!(case: :lower))
  end
end
