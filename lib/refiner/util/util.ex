defmodule Refiner.Util do
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

  @spec convert_to_bytes32(binary) :: binary
  def convert_to_bytes32(str) do
    Base.decode16!(str, case: :mixed)
  end

  defmodule GVA do
    @moduledoc """
    Global VAriable utilities.
    """

    @doc """
    Create a new table to hold your variables.
    A table can hold as much variables (and associated data) as your RAM allows you.
    """
    defmacro gnew(name) do
      quote do
        :ets.new(unquote(name), [:set, :public, :named_table])
      end
    end

    @doc """
    Check if a table exists.
    """
    defmacro gexists(name) do
      quote do
        :ets.info(unquote(name)) != :undefined
      end
    end

    @doc """
    Put a value in a variable table.
    """
    defmacro gput(table, key, value) do
      quote do
        :ets.insert(unquote(table), {unquote(key), unquote(value)})
      end
    end

    @doc """
    Get an variable's value from a table by it's key.
    """
    defmacro gget(table, key) do
      quote do
        [{_key, value}] = :ets.lookup(unquote(table), unquote(key))
        value
      end
    end
  end
end
