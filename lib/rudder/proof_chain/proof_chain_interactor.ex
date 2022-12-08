defmodule Rudder.ProofChain.Interactor do
  use GenServer

  @impl true
  def init(_) do
    {:ok, []}
  end

  @submit_brp_selector "submitBlockResultProof(uint64, uint64, bytes32, bytes32, string)"
  @is_session_closed_selector ABI.FunctionSelector.decode("isSessionClosed(uint64, uint64, bool) -> bool")

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

    submit_block_result_proof(
      chain_id,
      block_height,
      test_block_specimen_hash,
      test_block_result_hash,
      test_url
    )
  end

  def is_block_result_session_closed(chain_id, block_height) do
    rpc_params = [chain_id, block_height, false]

    proofchain_address = Application.get_env(:rudder, :proofchain_address)
    {:ok, to} = Rudder.PublicKeyHash.parse(proofchain_address)

    gas_price = Rudder.Network.EthereumMainnet.eth_gasPrice!()

    chain_id = Application.get_env(:rudder, :proofchain_chain_id)
    t = [
      from: nil,
      to: to,
      gas: 1000000,
      gas_price: gas_price,
      value: 0,
      data: {@is_session_closed_selector, rpc_params}
    ]

    with {:ok, res} <- Rudder.Network.EthereumMainnet.eth_call(t) do
      res
    end
  end


  def submit_block_result_proof(
        chain_id,
        block_height,
        block_specimen_hash,
        block_result_hash,
        url
      ) do
    data =
      ABI.encode(@submit_brp_selector, [
        chain_id,
        block_height,
        block_specimen_hash,
        block_result_hash,
        url
      ])

    operator_private_key = Application.get_env(:rudder, :operator_private_key)
    sender = Rudder.Wallet.load(Base.decode16!(operator_private_key, case: :lower))
    proofchain_address = Application.get_env(:rudder, :proofchain_address)
    {:ok, to} = Rudder.PublicKeyHash.parse(proofchain_address)

    {:ok, recent_gas_limit} = Rudder.Network.EthereumMainnet.gas_limit(:latest)

    estimated_gas_limit =
      Rudder.Network.EthereumMainnet.eth_estimateGas!(
        from: sender.address,
        to: to,
        data: data,
        gas: recent_gas_limit
      )

    nonce = Rudder.Network.EthereumMainnet.next_nonce(sender.address)
    gas_price = Rudder.Network.EthereumMainnet.eth_gasPrice!()

    chain_id = Application.get_env(:rudder, :proofchain_chain_id)

    tx = %Rudder.RPC.EthereumClient.Transaction{
      nonce: nonce,
      gas_price: gas_price,
      gas_limit: estimated_gas_limit,
      to: to,
      value: 0,
      data: data,
      chain_id: chain_id
    }

    signed_tx = Rudder.RPC.EthereumClient.Transaction.signed_by(tx, sender)

    with {:ok, res} <- Rudder.Network.EthereumMainnet.eth_sendTransaction(signed_tx) do
      :ok
    end
  end
end
