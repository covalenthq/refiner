defmodule Rudder.Util do
  @spec typeof(any) :: <<_::24, _::_*8>>
  def typeof(a) do
    cond do
      is_float(a) -> "float"
      is_number(a) -> "number"
      is_boolean(a) -> "boolean"
      is_nil(a) -> "nil"
      is_atom(a) -> "atom"
      is_binary(a) -> "binary"
      is_function(a) -> "function"
      is_list(a) -> "list"
      is_tuple(a) -> "tuple"
      is_exception(a) -> "exception"
      is_struct(a) -> "struct"
      is_map(a) -> "map"
      is_pid(a) -> "pid"
      is_bitstring(a) -> "bitstring"
      is_reference(a) -> "reference"
      is_port(a) -> "port"
      true -> "idunno"
    end
  end

  @spec get_file_paths(
          binary
          | maybe_improper_list(
              binary | maybe_improper_list(any, binary | []) | char,
              binary | []
            )
        ) :: [binary]
  def get_file_paths(dir_path) do
    try do
      Path.wildcard(dir_path)
    catch
      File.Error -> raise "could not find a file at path #{dir_path}"
    end
  end

  @spec extract_data(map, binary) :: list | {list, any}
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
