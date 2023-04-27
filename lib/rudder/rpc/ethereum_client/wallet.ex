defmodule Rudder.Wallet do
  defstruct [:private_key, :public_key, :address, :mnemonic_phrase]

  def new(), do: load(:crypto.strong_rand_bytes(32))

  def load(mnemonic_phrase: mnemonic) do
    Mnemonic.mnemonic_to_entropy(mnemonic)
    |> Base.decode16!(case: :mixed)
    |> load()
  end

  def load(raw_private_key)
      when is_binary(raw_private_key) and byte_size(raw_private_key) == 32 do
    {:ok, raw_public_key} = ExSecp256k1.create_public_key(raw_private_key)
    address = pubkey_to_address(raw_public_key)

    %__MODULE__{
      private_key: raw_private_key,
      public_key: raw_public_key,
      address: address,
      mnemonic_phrase: Mnemonic.entropy_to_mnemonic(raw_private_key)
    }
  end

  def sign(%__MODULE__{} = sender, tx) do
    Rudder.RPC.EthereumClient.Transaction.signed_by(tx, sender)
  end

  defp pubkey_to_address(<<4::size(8), key::binary-size(64)>>) do
    <<_::binary-size(12), raw_address::binary-size(20)>> = ExKeccak.hash_256(key)
    Rudder.RPC.PublicKeyHash.parse_raw!(raw_address)
  end
end
