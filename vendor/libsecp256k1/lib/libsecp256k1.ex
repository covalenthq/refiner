defmodule :libsecp256k1 do
  def sha256(bin) do
    :crypto.hash(:sha256, bin)
  end

  def dsha256(bin) do
    :crypto.hash(:sha256, :crypto.hash(:sha256, bin))
  end

  # stub functions to satisfy dependent libs

  def ec_pubkey_create(_privkey, :uncompressed), do: {:ok, nil}
  def ec_pubkey_create(_privkey, :compressed), do: {:ok, nil}

  def ec_pubkey_decompress(_pubkey), do: {:ok, nil}

  def ec_pubkey_verify(_pubkey), do: :ok

  def ec_privkey_export(_privkey, :compressed), do: {:ok, nil}
  def ec_privkey_import(_serialized_privkey), do: {:ok, nil}

  def ec_privkey_tweak_add(_privkey, _tweak), do: {:ok, nil}
  def ec_privkey_tweak_mul(_privkey, _tweak), do: {:ok, nil}

  def ec_pubkey_tweak_add(_pubkey, _tweak), do: {:ok, nil}
  def ec_pubkey_tweak_mul(_pubkey, _tweak), do: {:ok, nil}

  def ecdsa_sign(_msg, _privkey, :default, ""), do: {:ok, nil}
  def ecdsa_verify(_msg, _signature, _pubkey), do: :ok

  def ecdsa_sign_compact(_msg, _privkey, :default, ""), do: {:ok, nil, nil}
  def ecdsa_recover_compact(_msg, _signature, :uncompressed, _recovery_id), do: {:ok, nil}
  def ecdsa_verify_compact(_msg, _signature, _pubkey), do: :ok
end
