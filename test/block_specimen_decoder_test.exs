defmodule Rudder.BlockSpecimenDecoderTest do
  use ExUnit.Case, async: true

  setup do
    blockSpecimenDecoder = start_supervised(Rudder.Avro.BlockSpecimenDecoder)
    %{blockSpecimenDecoder: blockSpecimenDecoder}
  end

  test "Rudder.Avro.BlockSpecimenDecoder.list/0 returns an empty list", %{
    blockSpecimenDecoder: _blockSpecimenDecoder
  } do
    assert Rudder.Avro.BlockSpecimenDecoder.list() == :ok
  end

  test "Rudder.Avro.BlockSpecimenDecoder.get_schema/0 returns correct schema", %{
    blockSpecimenDecoder: _blockSpecimenDecoder
  } do
    assert Rudder.Avro.BlockSpecimenDecoder.get_schema() ==
             "com.covalenthq.brp.avro.ReplicationSegment"
  end

  test "Rudder.Avro.BlockSpecimenDecoder.decode_file/1 decodes binary specimen file", %{
    blockSpecimenDecoder: _blockSpecimenDecoder
  } do
    specimen_path =
      "./test-data/encoded/1-15892728-replica-0x84a541916d6d3c974b4da961e2f00a082c03a071132f5db27787124597c094c1"

    expected_start_block = 15_892_728
    expected_hash = "0x816c62d9c077d6d7423bb6ece430f40dcf53b38b9676d96ca0e120ee3ec5dcb9"

    {:ok, decoded_specimen} = Rudder.Avro.BlockSpecimenDecoder.decode_file(specimen_path)

    {:ok, decoded_specimen_start_block} = Map.fetch(decoded_specimen, "startBlock")
    {:ok, specimen_event} = Map.fetch(decoded_specimen, "replicaEvent")

    [head | _tail] = specimen_event
    decoded_specimen_hash = Map.get(head, "hash")

    assert decoded_specimen_start_block == expected_start_block
    assert decoded_specimen_hash == expected_hash
  end

  test "Rudder.Avro.BlockSpecimenDecoder.decode_dir/1 streams directory binary files", %{
    blockSpecimenDecoder: _blockSpecimenDecoder
  } do
    dir_path = "./test-data/encoded/*"

    expected_start_block = 15_892_728
    expected_last_block = 15_892_755

    expected_start_hash = "0x816c62d9c077d6d7423bb6ece430f40dcf53b38b9676d96ca0e120ee3ec5dcb9"
    expected_last_hash = "0xf335ebbe317d437b9736299a6ab9222ff20c6fc6252877c92c0e4a1d15ebfb55"

    decode_specimen_stream = Rudder.Avro.BlockSpecimenDecoder.decode_dir(dir_path)

    start_block_stream = List.first(decode_specimen_stream)
    last_block_stream = List.last(decode_specimen_stream)

    {:ok, decoded_start_block} =
      start_block_stream
      |> Enum.to_list()
      |> List.keytake(:ok, 0)
      |> elem(0)
      |> elem(1)
      |> Map.fetch("startBlock")

    {:ok, [head | _tail]} =
      start_block_stream
      |> Enum.to_list()
      |> List.keytake(:ok, 0)
      |> elem(0)
      |> elem(1)
      |> Map.fetch("replicaEvent")

    decoded_start_hash = Map.get(head, "hash")

    {:ok, decoded_last_block} =
      last_block_stream
      |> Enum.to_list()
      |> List.keytake(:ok, 0)
      |> elem(0)
      |> elem(1)
      |> Map.fetch("startBlock")

    {:ok, [head | _tail]} =
      last_block_stream
      |> Enum.to_list()
      |> List.keytake(:ok, 0)
      |> elem(0)
      |> elem(1)
      |> Map.fetch("replicaEvent")

    decoded_last_hash = Map.get(head, "hash")

    assert decoded_start_block == expected_start_block
    assert decoded_start_hash == expected_start_hash

    assert decoded_last_block == expected_last_block
    assert decoded_last_hash == expected_last_hash
  end

  test "Rudder.Avro.BlockSpecimenDecoder.decode_dir/1 decodes all binary files", %{
    blockSpecimenDecoder: _blockSpecimenDecoder
  } do
    dir_path = "./test-data/encoded/*"

    expected_specimens = 3

    decode_specimen_stream = Rudder.Avro.BlockSpecimenDecoder.decode_dir(dir_path)

    # stream resolved earlier to full specimen list
    resolved_stream = decode_specimen_stream |> Enum.map(fn x -> Enum.to_list(x) end)
    resolved_specimens = length(resolved_stream)

    assert resolved_specimens == expected_specimens
  end

end
