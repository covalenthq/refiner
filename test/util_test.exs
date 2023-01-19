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
    specimen_path =
      "./test-data/encoded/1-15892728-replica-0x84a541916d6d3c974b4da961e2f00a082c03a071132f5db27787124597c094c1"

    {:ok, decoded_specimen} = Rudder.Avro.BlockSpecimenDecoder.decode_file(specimen_path)

    assert Rudder.Util.typeof(decoded_specimen) == "idunno"
  end

  test "get_file_paths returns a list of files in the given directory" do
    assert Rudder.Util.get_file_paths("./test-data/block-specimen/*") == [
             "test-data/block-specimen/15892728.specimen.json",
             "test-data/block-specimen/15892740.specimen.json",
             "test-data/block-specimen/15892755.specimen.json"
           ]
  end

  test "get_file_paths returns an empty list when given a directory with no files or invalid path" do
    assert Rudder.Util.get_file_paths("./evm") == []
  end
end
