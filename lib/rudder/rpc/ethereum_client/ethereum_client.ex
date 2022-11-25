defmodule Rudder.RPC.EthereumClient do
  defmacro __using__(opts) do
    quote location: :keep, bind_quoted: [used_with_opts: opts] do
      use Confex, used_with_opts
      alias Rudder.RPC.EthereumClient.Codec
      alias Rudder.RPC.EthereumClient.Transaction

      @default_client_module Rudder.RPC.JSONRPC.HTTPClient
      @default_client_opts "http://127.0.0.1:8545"

      @default_selector List.last(Module.split(__MODULE__))
      @default_adapter Rudder.RPC.JSONRPC.HTTPAdapter

      @batch_load_path "var/batch_loads"

      def chain_id do
        Keyword.fetch!(config(), :chain_id)
      end

      def client do
        client_module = Keyword.get(config(), :client_module, @default_client_module)
        client_opts = Keyword.get(config(), :client_opts, @default_client_opts)
        client_module.get_or_create(__MODULE__, client_opts)
      end

      def block_sealed_at(_height, signed_at), do: signed_at

      def selector do
        Keyword.get(config(), :selector, @default_selector)
      end

      def description do
        Keyword.get(config(), :description, @default_selector)
      end

      def block_ripening_delay do
        case Keyword.fetch(config(), :block_ripening_delay) do
          {:ok, n} when is_integer(n) and n >= 0 ->
            n

          _ ->
            0
        end
      end

      def request_timeout_millis, do: 1_200_000

      def sealer do
        case Keyword.fetch(config(), :sealer) do
          {:ok, sealer_addr_str} ->
            Rudder.PublicKeyHash.parse!(sealer_addr_str)

          :error ->
            nil
        end
      end

      def configured? do
        with kws when is_list(kws) <- config(),
             config <- Map.new(kws) do
          case config do
            %{client_opts: opts} when is_binary(opts) -> true
            %{peer_uri: uri} when is_binary(uri) -> true
            _ -> false
          end
        else
          _ ->
            false
        end
      end

      def alive? do
        try do
          is_binary(web3_clientVersion!())
        rescue
          e in Rudder.RPCError ->
            false
        end
      end

      def call(rpc_method, rpc_params, decode_fun \\ nil) do
        default_opts = [
          keepalive: true,
          request_timeout: request_timeout_millis()
        ]

        resp = client() |> Rudder.RPC.JSONRPC.Client.call(rpc_method, rpc_params, default_opts)

        case {resp, decode_fun} do
          {{:ok, value}, f} when is_function(f, 1) -> {:ok, f.(value)}
          _ -> resp
        end
      end

      defmacrop unwrap!(rpc_resp) do
        quote do
          case unquote(rpc_resp) do
            {:ok, value} -> value
            error -> raise Rudder.RPCError, error
          end
        end
      end

      defmacrop unwrap_responses!(rpc_resp_stream) do
        quote do
          Stream.map(unquote(rpc_resp_stream), fn rpc_resp ->
            case rpc_resp do
              {:ok, value} -> value
              error -> raise Rudder.RPCError, error
            end
          end)
        end
      end

      defmacrop unwrap_or_discard_responses(rpc_resp_stream) do
        quote do
          Stream.flat_map(unquote(rpc_resp_stream), fn rpc_resp ->
            case rpc_resp do
              {:ok, nil} -> []
              {:ok, value} -> [value]
              _ -> []
            end
          end)
        end
      end

      def web3_clientVersion, do: call(:web3_clientVersion, [])

      def eth_chainId, do: call(:eth_chainId, [], &Codec.decode_qty/1)

      def eth_blockNumber, do: call(:eth_blockNumber, [], &Codec.decode_qty/1)

      def eth_getBlockByNumber(block_number, opts \\ []) do
        call(
          :eth_getBlockByNumber,
          [
            Codec.encode_default_block(block_number),
            Keyword.get(opts, :transactions, :hashes) == :full
          ],
          &Codec.decode_block(&1, __MODULE__)
        )
      end

      def eth_getBlockByHash(hash, opts \\ []) do
        call(
          :eth_getBlockByHash,
          [Codec.encode_sha256(hash), Keyword.get(opts, :transactions, :hashes) == :full],
          &Codec.decode_block(&1, __MODULE__)
        )
      end

      def eth_getLogs(opts \\ []) do
        call(
          :eth_getLogs,
          opts,
          nil
        )
      end

      def eth_getTransactionByHash(hash, opts \\ []),
        do:
          call(
            :eth_getTransactionByHash,
            [Codec.encode_sha256(hash)],
            &Codec.decode_transaction/1
          )

      def eth_getTransactionsByBlockNumber(block_number, opts \\ []) do
        call(
          :eth_getTransactionsByBlockNumber,
          [Codec.encode_default_block(block_number)],
          &Codec.decode_transactions/1
        )
      end

      def eth_getTransactionReceipt(hash, opts \\ []),
        do:
          call(
            :eth_getTransactionReceipt,
            [Codec.encode_sha256(hash)],
            &Codec.decode_transaction_receipt/1
          )

      def eth_getTransactionReceiptsByBlockNumber(block_number, opts \\ []) do
        call(
          :eth_getTransactionReceiptsByBlockNumber,
          [Codec.encode_default_block(block_number)],
          &Codec.decode_transaction_receipts/1
        )
      end

      def eth_gasPrice, do: call(:eth_gasPrice, [], &Codec.decode_qty/1)

      def eth_getTransactionCount(ledger_addr, at_block \\ :latest) do
        call(
          :eth_getTransactionCount,
          [Codec.encode_address(ledger_addr), Codec.encode_default_block(at_block)],
          &Codec.decode_qty/1
        )
      end

      def eth_getBalance(ledger_addr, at_block \\ :latest) do
        call(
          :eth_getBalance,
          [Codec.encode_address(ledger_addr), Codec.encode_default_block(at_block)],
          &Codec.decode_qty/1
        )
      end

      def eth_call(call_tx, at_block \\ :latest) do
        call(
          :eth_call,
          [Codec.encode_call_transaction(call_tx), Codec.encode_default_block(at_block)],
          &Codec.decode_call_result(&1, call_tx)
        )
      end

      def eth_estimateGas(call_tx, at_block \\ :latest) do
        call(
          :eth_estimateGas,
          [Codec.encode_call_transaction(call_tx), Codec.encode_default_block(at_block)],
          &Codec.decode_qty/1
        )
      end

      def eth_sendTransaction(call_tx, opts \\ []) do
        {:ok, promise_ref} =
          case call_tx do
            %Transaction{} = tx ->
              call(
                # :eth_sendTransaction,
                :eth_sendRawTransaction,
                [Codec.encode_transaction(tx)],
                & &1
              )

            tx_parts when is_list(tx_parts) or is_map(tx_parts) ->
              call(
                :eth_sendTransaction,
                [Codec.encode_call_transaction(call_tx)],
                & &1
              )

            tx_bin when is_binary(tx_bin) ->
              call(
                :eth_sendRawTransaction,
                [Codec.encode_bin(tx_bin)],
                & &1
              )
          end

        if opts[:sync] do
          poll_for_transaction_receipt(promise_ref)
        else
          {:ok, promise_ref}
        end
      end

      def poll_for_transaction_receipt(promise_ref) do
        case call(:eth_getTransactionReceipt, [promise_ref], & &1) do
          {:ok, nil} ->
            Process.sleep(100)
            poll_for_transaction_receipt(promise_ref)

          {:ok, result} ->
            {:ok, Codec.decode_transaction_receipt(result)}

          err ->
            err
        end
      end

      def getrawblock(pos_spec, opts \\ [])
      def getrawblock(nil, _opts), do: {:ok, nil}

      def getrawblock(pos_spec, opts) do
        full_transactions? = Keyword.get(opts, :transactions, :ids) == :full

        case pos_spec do
          pos when is_atom(pos) or is_integer(pos) ->
            call(:eth_getBlockByNumber, [Codec.encode_qty(pos), full_transactions?])

          %Rudder.SHA256{} = hash ->
            call(:eth_getBlockByHash, [Codec.encode_sha256(hash), full_transactions?])

          hash when is_binary(hash) ->
            call(:eth_getBlockByHash, [Codec.encode_sha256(hash), full_transactions?])
        end
      end

      def getrawblock!(pos_spec, opts \\ []) do
        unwrap!(getrawblock(pos_spec, opts))
      end

      def transact(call_tx \\ []) do
        call_tx =
          call_tx
          |> Keyword.put_new(:value, 0)
          |> Keyword.put_new(:gas, 1_000_000)
          |> Keyword.put_new(:gas_price, 1)
          |> Keyword.put_new(:from, :sealer)
          |> Keyword.put_new(:to, :sealer)
          |> Enum.map(fn
            {:from, :sealer} -> {:from, sealer()}
            {:to, :sealer} -> {:to, sealer()}
            other -> other
          end)

        eth_sendTransaction(call_tx)
      end

      def next_nonce(nil), do: 0

      def next_nonce(%Rudder.PublicKeyHash{} = pkh) do
        eth_getTransactionCount!(pkh, :pending)
      end

      def gas_limit(at_block \\ :latest) do
        with {:ok, blk} <-
               call(:eth_getBlockByNumber, [Codec.encode_default_block(at_block), false]),
             {:ok, gas_limit_str} <- Map.fetch(blk, "gasLimit") do
          {:ok, Codec.decode_qty(gas_limit_str)}
        else
          err -> err
        end
      end

      def web3_clientVersion!, do: unwrap!(web3_clientVersion())
      def eth_chainId!, do: unwrap!(eth_chainId())
      def eth_blockNumber!, do: unwrap!(eth_blockNumber())

      def eth_getBlockByNumber!(block_number, opts \\ []),
        do: unwrap!(eth_getBlockByNumber(block_number, opts))

      def eth_getBlockByHash!(hash, opts \\ []), do: unwrap!(eth_getBlockByHash(hash, opts))
      def eth_getLogs!(opts \\ []), do: unwrap!(eth_getLogs(opts))
      def eth_getTransactionByHash!(hash), do: unwrap!(eth_getTransactionByHash(hash))
      def eth_gasPrice!, do: unwrap!(eth_gasPrice())

      def eth_getTransactionCount!(ledger_addr, at_block \\ :latest),
        do: unwrap!(eth_getTransactionCount(ledger_addr, at_block))

      def eth_getBalance!(ledger_addr, at_block \\ :latest),
        do: unwrap!(eth_getBalance(ledger_addr, at_block))

      def eth_call!(call_tx, at_block \\ :latest), do: unwrap!(eth_call(call_tx, at_block))

      def eth_estimateGas!(call_tx, at_block \\ :latest),
        do: unwrap!(eth_estimateGas(call_tx, at_block))

      defoverridable alive?: 0,
                     eth_call: 1,
                     eth_call: 2,
                     eth_getTransactionReceiptsByBlockNumber: 1,
                     eth_getTransactionReceiptsByBlockNumber: 2,
                     block_sealed_at: 2,
                     request_timeout_millis: 0
    end
  end
end
