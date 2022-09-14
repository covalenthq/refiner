defmodule Rudder.RPC.JSONRPC.MultiHTTPClient do
  defstruct [:backing_clients, :pool_size]

  alias Rudder.RPC.JSONRPC.HTTPClient

  def get_or_create(owner, conn_uris) when is_binary(conn_uris) do
    get_or_create(owner, String.split(conn_uris, ","))
  end

  def get_or_create(owner, conn_uris) when is_list(conn_uris) do
    backing_clients =
      Enum.map(conn_uris, fn conn_uri ->
        HTTPClient.get_or_create(owner, conn_uri)
      end)

    %__MODULE__{
      backing_clients: :array.from_list(backing_clients),
      pool_size: length(backing_clients)
    }
  end

  def random_client(%__MODULE__{backing_clients: [cl]}) do
    cl
  end

  def random_client(%__MODULE__{backing_clients: cl, pool_size: sz}) do
    :array.get(:rand.uniform(sz) - 1, cl)
  end

  defimpl Rudder.RPC.JSONRPC.Client do
    def call(client, rpc_method, rpc_params, opts \\ []) do
      backing_client = Rudder.RPC.JSONRPC.MultiHTTPClient.random_client(client)
      Rudder.RPC.JSONRPC.Client.call(backing_client, rpc_method, rpc_params, opts)
    end

    def long_call(client, rpc_method, rpc_params) do
      backing_client = Rudder.RPC.JSONRPC.MultiHTTPClient.random_client(client)
      Rudder.RPC.JSONRPC.Client.long_call(backing_client, rpc_method, rpc_params)
    end

    def batch_call(client, rpc_method, rpc_params_stream, opts \\ []) do
      backing_client = Rudder.RPC.JSONRPC.MultiHTTPClient.random_client(client)
      Rudder.RPC.JSONRPC.Client.batch_call(backing_client, rpc_method, rpc_params_stream, opts)
    end

    def fetch_digest(client, uri_ref) do
      backing_client = Rudder.RPC.JSONRPC.MultiHTTPClient.random_client(client)
      Rudder.RPC.JSONRPC.Client.fetch_digest(backing_client, uri_ref)
    end

    def download(client, uri_ref, io_device) do
      backing_client = Rudder.RPC.JSONRPC.MultiHTTPClient.random_client(client)
      Rudder.RPC.JSONRPC.Client.download(backing_client, uri_ref, io_device)
    end

    def delete(client, uri_ref) do
      backing_client = Rudder.RPC.JSONRPC.MultiHTTPClient.random_client(client)
      Rudder.RPC.JSONRPC.Client.delete(backing_client, uri_ref)
    end
  end
end
