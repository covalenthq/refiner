defprotocol Rudder.RPC.JSONRPC.Client do
  def call(client, rpc_method, rpc_params, opts \\ [])
  def long_call(client, rpc_method, rpc_params)
  def batch_call(client, rpc_method, rpc_params_stream, opts \\ [])
  def download(client, uri_ref, io_device)
  def fetch_digest(client, uri_ref)
  def delete(client, uri_ref)
end
