defmodule Rudder.ProofChain.Interactor do
  use GenServer

  @impl true
  def init(_) do
    {:ok, []}
  end

  @proofchain_address "0xCF3d5540525D191D6492F1E0928d4e816c29778c"
  @submit_brp_selector "submitBlockResultProof(uint64, uint64, bytes32, bytes32, string)"

  def start_link(_) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

# "Block height is out of bounds for live sync"
# "Sender is not BLOCK_RESULT_PRODUCER_ROLE"
# "Invalid chain ID"
# "Invalid block height"
# "Session submissions have closed"
# "Max submissions limit exceeded"
# "Operator already submitted for the provided block hash"
# "Insufficiently staked to submit"

  def test_submit_block_result_proof(block_height) do
    test_block_specimen_hash = "525D191D6492F1E0928d4e816c29778c"
    test_block_result_hash = "525D191D6492F1E0928d4e816c29778c"
    test_url = "block_result.url"
    chain_id = 1
    submit_block_result_proof(chain_id, block_height, block_specimen_hash, block_result_hash, url)

  end

  def submit_block_result_proof(chain_id, block_height, block_specimen_hash, block_result_hash, url) do

    data =
       ABI.encode(@submit_brp_selector, [
        chain_id,
        block_height,
        test_block_specimen_hash,
        test_block_result_hash,
        test_url
      ])

    test_private_key = "8b3a350cf5c34c9194ca85829a2df0ec3153be0318b5e2d3348e872092edffba"
    sender = Rudder.Wallet.load( Base.decode16!(test_private_key, case: :lower))
    {:ok, to} = Rudder.PublicKeyHash.parse(@proofchain_address)

    {:ok, recent_gas_limit} = Rudder.Network.EthereumMainnet.gas_limit(:latest)

    {:ok, from} = Rudder.PublicKeyHash.parse("0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266")
    estimated_gas_limit =
      Rudder.Network.EthereumMainnet.eth_estimateGas!(
        from: sender.address,
        to: to,
        data: data,
        gas: recent_gas_limit
      )

    nonce = Rudder.Network.EthereumMainnet.next_nonce(sender.address)
    gas_price = Rudder.Network.EthereumMainnet.eth_gasPrice!()

    tx = %Rudder.RPC.EthereumClient.Transaction{
      nonce: nonce,
      gas_price: gas_price,
      gas_limit: estimated_gas_limit,
      to: to,
      value: 0,
      data: data,
      chain_id: 31337
    }

    signed_tx = Rudder.RPC.EthereumClient.Transaction.signed_by(tx, sender)

    with {:ok, res} <- Rudder.Network.EthereumMainnet.eth_sendTransaction(signed_tx) do
      IO.inspect(res)
      true
    end

  end

end
