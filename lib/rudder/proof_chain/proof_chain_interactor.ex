defmodule Rudder.ProofChain.Interactor do
  require Logger
  alias Rudder.Events
  use GenServer

  @impl true
  @spec init(any) :: {:ok, []}
  def init(_) do
    {:ok, []}
  end

  @submit_brp_selector "submitBlockResultProof(uint64, uint64, bytes32, bytes32, string)"
  @is_session_open_selector ABI.FunctionSelector.decode(
                              "isSessionOpen(uint64,uint64,address) -> bool"
                            )
  @get_urls_selector ABI.FunctionSelector.decode("getURLS(bytes32) -> string[] memory")

  @spec start_link(any) :: :ignore | {:error, any} | {:ok, pid}
  def start_link(_) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  defp get_bsp_proofchain() do
    proofchain_address = Application.get_env(:rudder, :bsp_proofchain_address)
    Rudder.RPC.PublicKeyHash.parse(proofchain_address)
  end

  defp get_brp_proofchain() do
    proofchain_address = Application.get_env(:rudder, :brp_proofchain_address)
    Rudder.RPC.PublicKeyHash.parse(proofchain_address)
  end

  defp make_call(data, proofchain) do
    tx = [
      from: nil,
      to: proofchain,
      value: 0,
      data: data
    ]

    with {:ok, res} <- Rudder.Network.EthereumMainnet.eth_call(tx) do
      res
    end
  end

  @spec get_urls(any) :: any
  def get_urls(hash) do
    rpc_params = [hash]
    data = {@get_urls_selector, rpc_params}
    bsp_proofchain = get_bsp_proofchain()
    make_call(data, bsp_proofchain)
  end

  @spec is_block_result_session_open(binary) :: any
  def is_block_result_session_open(block_height) do
    {block_height, _} = Integer.parse(block_height)
    operator = get_operator_wallet()
    chain_id = Application.get_env(:rudder, :block_specimen_chain_id)
    rpc_params = [chain_id, block_height, operator.address.bytes]
    data = {@is_session_open_selector, rpc_params}
    brp_proofchain = get_brp_proofchain()
    make_call(data, brp_proofchain)
  end

  defp get_operator_wallet() do
    operator_private_key = Application.get_env(:rudder, :operator_private_key)
    Rudder.Wallet.load(Base.decode16!(operator_private_key, case: :lower))
  end

  defp send_eip1559_signed_tx(
         sender,
         nonce,
         to,
         estimated_gas_limit,
         data,
         proofchain_chain_id,
         max_priority_fee_per_gas_hex
       ) do
    {:ok, block} = Rudder.Network.EthereumMainnet.eth_getBlockByNumber(:latest)
    base_fee = block.base_fee_per_gas
    "0x" <> max_priority_fee_per_gas_hex = max_priority_fee_per_gas_hex
    {max_priority_fee_per_gas, _} = Integer.parse(max_priority_fee_per_gas_hex, 16)
    max_fee_per_gas = 2 * base_fee + max_priority_fee_per_gas

    tx = %Rudder.RPC.EthereumClient.TransactionEIP1559{
      type: 2,
      nonce: nonce,
      to: to,
      gas_limit: estimated_gas_limit,
      max_fee_per_gas: max_fee_per_gas,
      max_priority_fee_per_gas: max_priority_fee_per_gas,
      value: 0,
      data: data,
      chain_id: proofchain_chain_id
    }

    Rudder.RPC.EthereumClient.TransactionEIP1559.signed_by(tx, sender)
  end

  defp get_eip1559_signed_tx(sender, nonce, to, estimated_gas_limit, data, proofchain_chain_id) do
    case proofchain_chain_id do
      # case for testing via hardhat node in absence of maxPriorityFeePerGas support
      31_337 ->
        {:ok, fee_history} = Rudder.Network.EthereumMainnet.eth_feeHistory()
        fee_history_list = Map.to_list(fee_history)

        max_priority_fee_per_gas_hex =
          List.last(List.last(Tuple.to_list(List.first(fee_history_list))))

        send_eip1559_signed_tx(
          sender,
          nonce,
          to,
          estimated_gas_limit,
          data,
          proofchain_chain_id,
          max_priority_fee_per_gas_hex
        )

      _ ->
        {:ok, max_priority_fee_per_gas_hex} =
          Rudder.Network.EthereumMainnet.eth_maxPriorityFeePerGas()

        send_eip1559_signed_tx(
          sender,
          nonce,
          to,
          estimated_gas_limit,
          data,
          proofchain_chain_id,
          max_priority_fee_per_gas_hex
        )
    end
  end

  defp get_legacy_signed_tx(sender, nonce, to, estimated_gas_limit, data, proofchain_chain_id) do
    gas_price = Rudder.Network.EthereumMainnet.eth_gasPrice!()

    tx = %Rudder.RPC.EthereumClient.Transaction{
      nonce: nonce,
      gas_price: gas_price,
      gas_limit: estimated_gas_limit,
      to: to,
      value: 0,
      data: data,
      chain_id: proofchain_chain_id
    }

    Rudder.RPC.EthereumClient.Transaction.signed_by(tx, sender)
  end

  @spec submit_block_result_proof(any, any, any, any, any) :: any
  def submit_block_result_proof(
        chain_id,
        block_height,
        block_specimen_hash,
        block_result_hash,
        url
      ) do
    start_proof_ms = System.monotonic_time(:millisecond)

    data =
      ABI.encode_call_payload(@submit_brp_selector, [
        chain_id,
        block_height,
        block_specimen_hash,
        block_result_hash,
        url
      ])

    sender = get_operator_wallet()
    {:ok, to} = get_brp_proofchain()

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
      proofchain_chain_id = Application.get_env(:rudder, :proofchain_chain_id)

      signed_tx =
        get_eip1559_signed_tx(sender, nonce, to, estimated_gas_limit, data, proofchain_chain_id)

      with {:ok, txid} <- Rudder.Network.EthereumMainnet.eth_sendTransaction(signed_tx) do
        :ok = Events.brp_proof(System.monotonic_time(:millisecond) - start_proof_ms)
        Logger.info("#{block_height} txid is #{txid}")
        {:ok, :submitted}
      end
    rescue
      e in Rudder.RPCError ->
        cond do
          String.contains?(e.message, "Operator already submitted for the provided block hash") ->
            {:ok, :submitted}

          String.contains?(e.message, "Sender is not BLOCK_RESULT_PRODUCER_ROLE") or
            String.contains?(e.message, "Invalid chain ID") or
              String.contains?(e.message, "Insufficiently staked to submit") ->
            {:error, :irreparable, e.message}

          String.contains?(e.message, "Module(ModuleError") ->
            Logger.error(
              "error for block_height:#{block_height}; bspech:bresulth = (#{inspect(block_specimen_hash)}, #{inspect(block_result_hash)}); url:#{inspect(url)}"
            )

            {:error, e.message}

          true ->
            Logger.error("error in connecting to RPC: #{inspect(e)}")
            {:error, e.message}
        end
    end
  end
end
