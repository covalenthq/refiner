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
      "./test-data/block-specimens/1-15127599-replica-0x167a4a9380713f133aa55f251fd307bd88dfd9ad1f2087346e1b741ff47ba7f5"

    expected_start_block = 15_127_599
    expected_hash = "0x8f858356c48b270221814f8c1b2eb804a5fbd3ac7774b527f2fe0605be03fb37"

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
    dir_path = "./test-data/block-specimens/*"

    expected_start_block = 15_127_599
    expected_last_block = 15_127_603

    expected_start_hash = "0x8f858356c48b270221814f8c1b2eb804a5fbd3ac7774b527f2fe0605be03fb37"
    expected_last_hash = "0x9119289fc6a4a0c2b404019d7e16a7e850590f37312109b97c1fd4e940accfd3"

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
    dir_path = "./test-data/block-specimens/*"

    expected_specimens = 5

    decode_specimen_stream = Rudder.Avro.BlockSpecimenDecoder.decode_dir(dir_path)

    # stream resolved earlier to full specimen list
    resolved_stream = decode_specimen_stream |> Enum.map(fn x -> Enum.to_list(x) end)
    resolved_specimens = length(resolved_stream)

    assert resolved_specimens == expected_specimens
  end

  # test "Crashes blockSpecimenDecoder but not application", %{
  #   blockSpecimenDecoder: blockSpecimenDecoder
  # } do

  #   children = :supervisor.count_children(blockSpecimenDecoder)

  #   assert children == 1

  # end
end
