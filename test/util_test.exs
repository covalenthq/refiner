defmodule Rudder.UtilTest do
  use ExUnit.Case

  test "returns 'float' for a float" do
    assert Rudder.Util.typeof(1.0) == "float"
  end

  test "returns 'number' for an integer" do
    assert Rudder.Util.typeof(1) == "number"
  end

  test "returns 'atom' for an atom" do
    assert Rudder.Util.typeof(:my_atom) == "atom"
  end

  test "returns 'boolean' for a boolean" do
    assert Rudder.Util.typeof(true) == "boolean"
    assert Rudder.Util.typeof(false) == "boolean"
  end

  test "returns 'binary' for a binary" do
    assert Rudder.Util.typeof("hello world") == "binary"
  end

  test "returns 'function' for a function" do
    assert Rudder.Util.typeof(fn -> :ok end) == "function"
  end

  test "returns 'list' for a list" do
    assert Rudder.Util.typeof([1, 2, 3]) == "list"
  end

  test "returns 'tuple' for a tuple" do
    assert Rudder.Util.typeof({1, 2, 3}) == "tuple"
  end

  test "returns 'idunno' for other types" do
    assert Rudder.Util.typeof() == "idunno"
  end
end
