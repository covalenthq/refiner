defprotocol Rudder.RPC.JSONRPC.Client do
  def call(client, rpc_method, rpc_params, opts \\ [])
  def long_call(client, rpc_method, rpc_params)
  def delete(client, uri_ref)
end
