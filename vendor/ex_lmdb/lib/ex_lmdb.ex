defmodule ExLMDB.Database do
  def open(_db_path, _opts, _block), do: {:ok, nil}
  def open!(_db_path, _opts, _block), do: {:ok, nil}
  def get(_block, _key), do: :not_found
  def record_count(_), do: 0
  def empty?(_), do: true
end

defmodule ExLMDB.Transaction do
  def begin(_db, _opts, _block), do: {:ok, nil}
  def put(_tx, _key, _value), do: :ok
end
