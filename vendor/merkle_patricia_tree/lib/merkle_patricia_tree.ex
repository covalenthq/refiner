defmodule MerklePatriciaTree.Trie do
  @type root_hash :: binary()

  defstruct []
  
  def empty_trie_root_hash, do: <<0::256>>
end
