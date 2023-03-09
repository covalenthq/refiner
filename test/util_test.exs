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

  test "returns 'map' for a map" do
    result_path = "./test-data/block-result/16791900.result.json"

    {:ok, result_binary} = File.read(result_path)
    {:ok, result_decoded_map} = Poison.decode(result_binary)

    specimen_path =
      "./test-data/encoded/1-16791900-replica-0xcd89a7529f3bd7896ef11681bbf5f58b498d4311ec18479d7b1794101f48a767"

    {:ok, decoded_specimen} = Rudder.Avro.BlockSpecimen.decode_file(specimen_path)

    assert Rudder.Util.typeof(decoded_specimen) == "map"
    assert Rudder.Util.typeof(result_decoded_map) == "map"
  end

  test "returns 'pid' for a pid" do
    assert Rudder.Util.typeof(self()) == "pid"
  end

  test "returns 'bitstring' for a bitstring" do
    assert Rudder.Util.typeof(<<3::4>>) == "bitstring"
  end

  test "returns 'nil' for an nil" do
    assert Rudder.Util.typeof(nil) == "nil"
  end

  test "returns 'struct' for a struct" do
    block_result_metadata = %Rudder.BlockResultMetadata{
      chain_id: 1,
      block_height: 16_791_900,
      block_specimen_hash: 0xCD89A7529F3BD7896EF11681BBF5F58B498D4311EC18479D7B1794101F48A767,
      file_path: "./test-data/block-result/16791900.result.json"
    }

    assert Rudder.Util.typeof(block_result_metadata) == "struct"
  end

  test "returns 'exception' for an exception" do
    assert Rudder.Util.typeof(%RuntimeError{}) == "exception"
  end

  test "returns 'reference' for a reference" do
    ref_1 = Kernel.make_ref()
    assert Rudder.Util.typeof(ref_1) == "reference"
  end

  test "returns 'port' for a port" do
    port = Port.open({:spawn, "cat"}, [:binary])
    assert Rudder.Util.typeof(port) == "port"
  end

  test "get_file_paths returns a list of files in the given directory" do
    assert Rudder.Util.get_file_paths("./test-data/block-specimen/*") == [
             "test-data/block-specimen/16791900.specimen.json",
             "test-data/block-specimen/16792200.specimen.json",
             "test-data/block-specimen/16792500.specimen.json"
           ]
  end

  test "get_file_paths returns an empty list when given a directory with no files or invalid path" do
    assert Rudder.Util.get_file_paths("./evm") == []
  end

  test "converts a hexadecimal string to a 32-byte binary string" do
    assert Rudder.Util.convert_to_bytes32("0123456789abcdef") ==
             <<1, 35, 69, 103, 137, 171, 205, 239>>
  end

  test "raises an error if the input string is not a hexadecimal string" do
    assert_raise ArgumentError, "non-alphabet digit found: \"n\" (byte 110)", fn ->
      Rudder.Util.convert_to_bytes32("not-a-hex-string")
    end
  end
end
