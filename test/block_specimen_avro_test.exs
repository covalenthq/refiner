defmodule Refiner.BlockSpecimenDecoderEncoderTest do
  use ExUnit.Case, async: true

  setup do
    block_specimen_avro = start_supervised(Refiner.Avro.BlockSpecimen)
    %{block_specimen_avro: block_specimen_avro}
  end

  test "Refiner.Avro.BlockSpecimen.list/0 returns an empty list", %{
    block_specimen_avro: _block_specimen_avro
  } do
    assert Refiner.Avro.BlockSpecimen.list() == :ok
  end

  test "Refiner.Avro.BlockSpecimen.get_schema/0 returns correct schema", %{
    block_specimen_avro: _block_specimen_avro
  } do
    assert Refiner.Avro.BlockSpecimen.get_schema() ==
             "com.covalenthq.brp.avro.ReplicationSegment"
  end

  test "Refiner.Avro.BlockSpecimen.decode_file/1 decodes binary specimen file", %{
    block_specimen_avro: _block_specimen_avro
  } do
    specimen_path =
      "./test-data/codec-0.36/encoded/1-19434485-replica-0x5800aab40ca1c9aedae3329ad82ad051099edaa293d68504b987a12acfa7b799"

    expected_start_block = 19_434_485
    expected_hash = "0x3cf79c299079befbbf7852364921455e75d6b73cef1b559f6791fd0490160836"

    {:ok, decoded_specimen} = Refiner.Avro.BlockSpecimen.decode_file(specimen_path)

    {:ok, decoded_specimen_start_block} = Map.fetch(decoded_specimen, "startBlock")
    {:ok, specimen_event} = Map.fetch(decoded_specimen, "replicaEvent")

    [head | _tail] = specimen_event
    decoded_specimen_hash = Map.get(head, "hash")

    assert decoded_specimen_start_block == expected_start_block
    assert decoded_specimen_hash == expected_hash
  end

  test "Refiner.Avro.BlockSpecimen.decode_dir/1 streams directory binary files", %{
    block_specimen_avro: _block_specimen_avro
  } do
    dir_path = "./test-data/codec-0.36/encoded/*"

    expected_start_block = 19_434_485
    expected_last_block = 19_434_555

    expected_start_hash = "0x3cf79c299079befbbf7852364921455e75d6b73cef1b559f6791fd0490160836"
    expected_last_hash = "0xe8da96c1936beca082677f0a634f659970f1646b3a6ca2d555f038aeb076e006"

    decode_specimen_stream = Refiner.Avro.BlockSpecimen.decode_dir(dir_path)

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

  test "Refiner.Avro.BlockSpecimen.decode_dir/1 decodes all binary files", %{
    block_specimen_avro: _block_specimen_avro
  } do
    dir_path = "./test-data/codec-0.36/encoded/*"

    expected_specimens = 3

    decode_specimen_stream = Refiner.Avro.BlockSpecimen.decode_dir(dir_path)

    # stream resolved earlier to full specimen list
    resolved_stream = decode_specimen_stream |> Enum.map(fn x -> Enum.to_list(x) end)
    resolved_specimens = length(resolved_stream)

    assert resolved_specimens == expected_specimens
  end

  test "Refiner.Avro.BlockSpecimen.encode_file/1 encodes segment json file", %{
    block_specimen_avro: _block_specimen_avro
  } do
    segment_path = "./test-data/codec-0.36/segment/19434485.segment.json"

    expected_start_block = 19_434_485
    expected_hash = "0x3cf79c299079befbbf7852364921455e75d6b73cef1b559f6791fd0490160836"

    {:ok, encoded_segment_avro} = Refiner.Avro.BlockSpecimen.encode_file(segment_path)

    {:ok, decoded_segment_avro} =
      Avrora.decode_plain(encoded_segment_avro, schema_name: "block-ethereum")

    {:ok, decoded_segment_start_block} = Map.fetch(decoded_segment_avro, "startBlock")
    {:ok, replica_event} = Map.fetch(decoded_segment_avro, "replicaEvent")

    [head | _tail] = replica_event
    decoded_segment_hash = Map.get(head, "hash")

    assert decoded_segment_start_block == expected_start_block
    assert decoded_segment_hash == expected_hash
  end

  test "Refiner.Avro.BlockSpecimen.encode_dir/1 streams encoded .json files", %{
    block_specimen_avro: _block_specimen_avro
  } do
    dir_path = "./test-data/codec-0.36/segment/*"

    expected_start_block = 19_434_485
    expected_last_block = 19_434_555

    encoded_segment_stream = Refiner.Avro.BlockSpecimen.encode_dir(dir_path)

    start_segment_stream = List.first(encoded_segment_stream)
    last_segment_stream = List.last(encoded_segment_stream)

    encoded_start_segment_bytes =
      start_segment_stream
      |> Enum.to_list()
      |> List.keytake(:ok, 0)
      |> elem(0)
      |> elem(1)

    {:ok, decoded_start_segment} =
      Avrora.decode_plain(encoded_start_segment_bytes, schema_name: "block-ethereum")

    decoded_start_segment_number = Map.get(decoded_start_segment, "startBlock")

    encoded_last_segment_bytes =
      last_segment_stream
      |> Enum.to_list()
      |> List.keytake(:ok, 0)
      |> elem(0)
      |> elem(1)

    {:ok, decoded_last_segment} =
      Avrora.decode_plain(encoded_last_segment_bytes, schema_name: "block-ethereum")

    decoded_last_segment_number = Map.get(decoded_last_segment, "startBlock")

    assert decoded_start_segment_number == expected_start_block
    assert decoded_last_segment_number == expected_last_block
  end
end
