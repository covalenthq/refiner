defmodule Rudder.DecodeBlockSpecimenTest do
  use ExUnit.Case, async: true

  setup do
    decodeBlockSpecimen = start_supervised(Rudder.Avro.DecodeBlockSpecimen)
    %{decodeBlockSpecimen: decodeBlockSpecimen}
  end

  test "Rudder.Avro.DecodeBlockSpecimen.list/0 returns an empty list", %{decodeBlockSpecimen: _decodeBlockSpecimen} do

    assert Rudder.Avro.DecodeBlockSpecimen.list == []
  end

  test "Rudder.Avro.DecodeBlockSpecimen.get_schema/0 returns correct schema", %{decodeBlockSpecimen: _decodeBlockSpecimen} do

    assert Rudder.Avro.DecodeBlockSpecimen.get_schema == "com.covalenthq.brp.avro.ReplicationSegment"
  end

  test "Rudder.Avro.DecodeBlockSpecimen.decode_file/1 decodes binary specimen file", %{decodeBlockSpecimen: _decodeBlockSpecimen} do

    specimen_path = "./test-data/1-15127599-replica-0x167a4a9380713f133aa55f251fd307bd88dfd9ad1f2087346e1b741ff47ba7f5"

    expected_start_block = 15127599
    expected_hash = "0x8f858356c48b270221814f8c1b2eb804a5fbd3ac7774b527f2fe0605be03fb37"

    {:ok, decoded_specimen} = Rudder.Avro.DecodeBlockSpecimen.decode_file(specimen_path)

    {:ok, decoded_specimen_start_block} = Map.fetch(decoded_specimen, "startBlock")
    {:ok, specimen_event} = Map.fetch(decoded_specimen, "replicaEvent")

    [head | _tail] = specimen_event
    decoded_specimen_hash = Map.get(head, "hash")

    assert decoded_specimen_start_block ==  expected_start_block
    assert decoded_specimen_hash == expected_hash
  end


  # test "Rudder.Avro.DecodeBlockSpecimen.decode_files/1 decodes multiple files", %{decodeBlockSpecimen: decodeBlockSpecimen} do

  #   dir_path = "./test-data/*"

  #   expected_start_block = 15127599
  #   expected_end_block = 15127603

  #   expected_start_hash = "0x8f858356c48b270221814f8c1b2eb804a5fbd3ac7774b527f2fe0605be03fb37"

end
