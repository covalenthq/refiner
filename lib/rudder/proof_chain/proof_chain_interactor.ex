defmodule Rudder.ProofChain.Interactor do
  require Logger
  use GenServer

  @impl true
  def init(_) do
    {:ok, []}
  end

  @submit_brp_selector "submitBlockResultProof(uint64, uint64, bytes32, bytes32, string)"
  @is_session_open_selector ABI.FunctionSelector.decode(
                              "isSessionOpen(uint64,uint64,bool,address) -> bool"
                            )
  @get_urls_selector ABI.FunctionSelector.decode("getURLS(bytes32) -> string[] memory")

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

  defp make_call(data) do
    proofchain_address = Application.get_env(:rudder, :proofchain_address)
    {:ok, to} = Rudder.PublicKeyHash.parse(proofchain_address)

    gas_price = Rudder.Network.EthereumMainnet.eth_gasPrice!()

    tx = [
      from: nil,
      to: to,
      gas: 1_000_000,
      gas_price: gas_price,
      value: 0,
      data: data
    ]

    with {:ok, res} <- Rudder.Network.EthereumMainnet.eth_call(tx) do
      res
    end
  end

  def get_urls(hash) do
    rpc_params = [hash]
    data = {@get_urls_selector, rpc_params}
    make_call(data)
  end

  def is_block_result_session_open(block_height) do
    {block_height, _} = Integer.parse(block_height)
    operator = get_operator_wallet()
    chain_id = Application.get_env(:rudder, :proofchain_chain_id)
    rpc_params = [chain_id, block_height, false, operator.address.bytes]
    data = {@is_session_open_selector, rpc_params}
    make_call(data)
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
      ABI.encode_call_payload(@submit_brp_selector, [
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

    try do
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
    rescue
      e in Rudder.RPCError ->
        if String.contains?(e.message, "Operator already submitted for the provided block hash") do
          :ok
        else
          Logger.error("error in connecting to RPC: #{inspect(e)}")
          :error
        end
    end
  end
end
