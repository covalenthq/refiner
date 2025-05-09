defmodule Refiner.UtilTest do
  use ExUnit.Case

  test "returns 'float' for a float" do
    assert Refiner.Util.typeof(1.0) == "float"
  end

  test "returns 'number' for an integer" do
    assert Refiner.Util.typeof(1) == "number"
  end

  test "returns 'atom' for an atom" do
    assert Refiner.Util.typeof(:my_atom) == "atom"
  end

  test "returns 'boolean' for a boolean" do
    assert Refiner.Util.typeof(true) == "boolean"
    assert Refiner.Util.typeof(false) == "boolean"
  end

  test "returns 'binary' for a binary" do
    assert Refiner.Util.typeof("hello world") == "binary"
  end

  test "returns 'function' for a function" do
    assert Refiner.Util.typeof(fn -> :ok end) == "function"
  end

  test "returns 'list' for a list" do
    assert Refiner.Util.typeof([1, 2, 3]) == "list"
  end

  test "returns 'tuple' for a tuple" do
    assert Refiner.Util.typeof({1, 2, 3}) == "tuple"
  end

  test "returns 'map' for a map" do
    result_path = "./test-data/codec-0.38/block-result/22434160.result.json"

    {:ok, result_binary} = File.read(result_path)
    {:ok, result_decoded_map} = Poison.decode(result_binary)

    specimen_path = "./test-data/codec-0.38/encoded/1-22434160"

    {:ok, decoded_specimen} = Refiner.Avro.BlockSpecimen.decode_file(specimen_path)

    assert Refiner.Util.typeof(decoded_specimen) == "map"
    assert Refiner.Util.typeof(result_decoded_map) == "map"
  end

  test "returns 'pid' for a pid" do
    assert Refiner.Util.typeof(self()) == "pid"
  end

  test "returns 'bitstring' for a bitstring" do
    assert Refiner.Util.typeof(<<3::4>>) == "bitstring"
  end

  test "returns 'nil' for an nil" do
    assert Refiner.Util.typeof(nil) == "nil"
  end

  test "returns 'struct' for a struct" do
    block_result_metadata = %Refiner.BlockResultMetadata{
      chain_id: 1,
      block_height: 22_434_160,
      block_specimen_hash: 0xA8F265CAA9F4C340AEBCAC6A382E0D5422097FCF0E8A0F68E52EF90609D5FEDC,
      file_path: "./test-data/codec-0.38/block-result/22434160.result.json"
    }

    assert Refiner.Util.typeof(block_result_metadata) == "struct"
  end

  test "returns 'exception' for an exception" do
    assert Refiner.Util.typeof(%RuntimeError{}) == "exception"
  end

  test "returns 'reference' for a reference" do
    ref_1 = Kernel.make_ref()
    assert Refiner.Util.typeof(ref_1) == "reference"
  end

  test "returns 'port' for a port" do
    port = Port.open({:spawn, "cat"}, [:binary])
    assert Refiner.Util.typeof(port) == "port"
  end

  test "get_file_paths returns a list of files in the given directory" do
    assert Refiner.Util.get_file_paths("./test-data/codec-0.38/block-specimen/*") == [
             "test-data/codec-0.38/block-specimen/22433670.specimen.json",
             "test-data/codec-0.38/block-specimen/22433775.specimen.json",
             "test-data/codec-0.38/block-specimen/22434160.specimen.json"
           ]
  end

  test "get_file_paths returns an empty list when given a directory with no files or invalid path" do
    assert Refiner.Util.get_file_paths("./evm") == []
  end

  test "converts a hexadecimal string to a 32-byte binary string" do
    assert Refiner.Util.convert_to_bytes32("0123456789abcdef") ==
             <<1, 35, 69, 103, 137, 171, 205, 239>>
  end

  test "raises an error if the input string is not a hexadecimal string" do
    assert_raise ArgumentError, "non-alphabet character found: \"n\" (byte 110)", fn ->
      Refiner.Util.convert_to_bytes32("not-a-hex-string")
    end
  end
end
