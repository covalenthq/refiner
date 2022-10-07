defmodule Rudder.ProofChain.Utils do

  def extract_data(block_data, signature) do
    {:ok, data} = Map.fetch(block_data, "data")
    "0x" <> data = data
    fs = ABI.FunctionSelector.decode(signature)
    ABI.decode(fs, data |> Base.decode16!(case: :lower))
  end

end
