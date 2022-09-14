defmodule Exleveldb do
  def open(_db_name, _opts \\ []), do: {:ok, nil}
  def get(_db_ref, _key), do: :not_found
  def put(_db_ref, _key, _value), do: :ok
end
