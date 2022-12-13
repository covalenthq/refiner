defmodule Rudder.ProofChain.Interactor do
  use GenServer

  @impl true
  def init(_) do
    {:ok, []}
  end

  @submit_brp_selector "submitBlockResultProof(uint64, uint64, bytes32, bytes32, string)"
  @is_session_closed_selector ABI.FunctionSelector.decode(
                                "isSessionOpen(uint64, uint64, address, bool) -> bool"
                              )

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

  def is_block_result_session_open(block_height) do
    operator = get_operator_wallet()
    operator_address = operator.address
    chain_id = Application.get_env(:rudder, :proofchain_chain_id)

    rpc_params = [chain_id, block_height, false, operator_address]

    proofchain_address = Application.get_env(:rudder, :proofchain_address)
    {:ok, to} = Rudder.PublicKeyHash.parse(proofchain_address)

    gas_price = Rudder.Network.EthereumMainnet.eth_gasPrice!()

    tx = [
      from: nil,
      to: to,
      gas: 1_000_000,
      gas_price: gas_price,
      value: 0,
      data: {@is_session_open_selector, rpc_params}
    ]

    with {:ok, res} <- Rudder.Network.EthereumMainnet.eth_call(tx) do
      res
    end
  end

  defp get_operator_wallet() do
    operator_private_key = Application.get_env(:rudder, :operator_private_key)
    Rudder.Wallet.load(Base.decode16!(operator_private_key, case: :lower))
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

    sender = get_operator_wallet()
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
