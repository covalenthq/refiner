defmodule :keccakf1600 do
  def sha3_256(bin) do
    ExKeccak.hash_256(bin)
  end
end
