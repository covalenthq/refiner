defprotocol Rudder.RPC.JSONRPC.Client do
  @spec call(t, any, any, any) :: any
  def call(client, rpc_method, rpc_params, opts \\ [])
  @spec long_call(t, any, any) :: any
  def long_call(client, rpc_method, rpc_params)
  @spec delete(t, any) :: any
  def delete(client, uri_ref)
end
