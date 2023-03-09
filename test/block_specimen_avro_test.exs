defmodule Rudder.BlockSpecimenDecoderTest do
  use ExUnit.Case, async: true

  setup do
    block_specimen_decoder = start_supervised(Rudder.Avro.BlockSpecimen)
    %{block_specimen_decoder: block_specimen_decoder}
  end

  test "Rudder.Avro.BlockSpecimen.list/0 returns an empty list", %{
    block_specimen_decoder: _block_specimen_decoder
  } do
    assert Rudder.Avro.BlockSpecimen.list() == :ok
  end

  test "Rudder.Avro.BlockSpecimen.get_schema/0 returns correct schema", %{
    block_specimen_decoder: _block_specimen_decoder
  } do
    assert Rudder.Avro.BlockSpecimen.get_schema() ==
             "com.covalenthq.brp.avro.ReplicationSegment"
  end

  test "Rudder.Avro.BlockSpecimen.decode_file/1 decodes binary specimen file", %{
    block_specimen_decoder: _block_specimen_decoder
  } do
    specimen_path =
      "./test-data/encoded/1-16791900-replica-0xcd89a7529f3bd7896ef11681bbf5f58b498d4311ec18479d7b1794101f48a767"

    expected_start_block = 16_791_900
    expected_hash = "0x097b92af3601d850a834d03189a6f7a1a5a0f3cf0791197e3314efcd5c596e85"

    {:ok, decoded_specimen} = Rudder.Avro.BlockSpecimen.decode_file(specimen_path)

    {:ok, decoded_specimen_start_block} = Map.fetch(decoded_specimen, "startBlock")
    {:ok, specimen_event} = Map.fetch(decoded_specimen, "replicaEvent")

    [head | _tail] = specimen_event
    decoded_specimen_hash = Map.get(head, "hash")

    assert decoded_specimen_start_block == expected_start_block
    assert decoded_specimen_hash == expected_hash
  end

  test "Rudder.Avro.BlockSpecimen.decode_dir/1 streams directory binary files", %{
    block_specimen_decoder: _block_specimen_decoder
  } do
    dir_path = "./test-data/encoded/*"

    expected_start_block = 16_791_900
    expected_last_block = 16_792_500

    expected_start_hash = "0x097b92af3601d850a834d03189a6f7a1a5a0f3cf0791197e3314efcd5c596e85"
    expected_last_hash = "0x46f97723e7f8736626346a7878e43e07ed0e00bcf06a7dce59ba292ea74b6397"

    decode_specimen_stream = Rudder.Avro.BlockSpecimen.decode_dir(dir_path)

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

  test "Rudder.Avro.BlockSpecimen.decode_dir/1 decodes all binary files", %{
    block_specimen_decoder: _block_specimen_decoder
  } do
    dir_path = "./test-data/encoded/*"

    expected_specimens = 3

    decode_specimen_stream = Rudder.Avro.BlockSpecimen.decode_dir(dir_path)

    # stream resolved earlier to full specimen list
    resolved_stream = decode_specimen_stream |> Enum.map(fn x -> Enum.to_list(x) end)
    resolved_specimens = length(resolved_stream)

    assert resolved_specimens == expected_specimens
  end

  test "Rudder.Avro.BlockSpecimen.encode_file/1 encodes segment json file", %{
    block_specimen_decoder: _block_specimen_decoder
  } do
    segment_path = "./test-data/segment/16791900.segment.json"

    expected_start_block = 16_791_900
    expected_hash = "0x097b92af3601d850a834d03189a6f7a1a5a0f3cf0791197e3314efcd5c596e85"

    {:ok, encoded_segment_avro} = Rudder.Avro.BlockSpecimen.encode_file(segment_path)

    {:ok, decoded_segment_avro} =
      Avrora.decode(encoded_segment_avro, schema_name: "block-ethereum")

    [head | tail] = decoded_segment_avro

    {:ok, decoded_segment_start_block} = Map.fetch(head, "startBlock")
    {:ok, replica_event} = Map.fetch(head, "replicaEvent")

    [head | _tail] = replica_event
    decoded_segment_hash = Map.get(head, "hash")

    assert decoded_segment_start_block == expected_start_block
    assert decoded_segment_hash == expected_hash
  end

  test "Rudder.Avro.BlockSpecimen.encode_dir/1 streams encoded .json files", %{
    block_specimen_decoder: _block_specimen_decoder
  } do
    dir_path = "./test-data/segment/*"

    expected_start_block = 16_791_900
    expected_last_block = 16_792_500

    encoded_segment_stream = Rudder.Avro.BlockSpecimen.encode_dir(dir_path)

    start_segment_stream = List.first(encoded_segment_stream)
    last_segment_stream = List.last(encoded_segment_stream)

    encoded_start_segment_bytes =
      start_segment_stream
      |> Enum.to_list()
      |> List.keytake(:ok, 0)
      |> elem(0)
      |> elem(1)

    {:ok, decoded_start_segment} =
      Avrora.decode(encoded_start_segment_bytes, schema_name: "block-ethereum")

    [head | _tail] = decoded_start_segment
    decoded_start_segment_number = Map.get(head, "startBlock")

    encoded_last_segment_bytes =
      last_segment_stream
      |> Enum.to_list()
      |> List.keytake(:ok, 0)
      |> elem(0)
      |> elem(1)

    {:ok, decoded_last_segment} =
      Avrora.decode(encoded_last_segment_bytes, schema_name: "block-ethereum")

    [head | _tail] = decoded_last_segment
    decoded_last_segment_number = Map.get(head, "startBlock")

    assert decoded_start_segment_number == expected_start_block
    assert decoded_last_segment_number == expected_last_block
  end
end
