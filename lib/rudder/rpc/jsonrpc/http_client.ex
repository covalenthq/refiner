defmodule Rudder.RPC.JSONRPC.HTTPClient do
  defstruct [:request_uri, :ws_request_uri, :request_headers]
  alias Rudder.RPC.JSONRPC.HTTPAdapter, as: Adapter
  alias Rudder.RPC.JSONRPC.WSAdapter, as: LongCallAdapter

  def get_or_create(owner, conn_uri) when is_binary(conn_uri) do
    get_or_create(owner, URI.parse(conn_uri))
  end

  def get_or_create(_owner, %URI{} = conn_uri) do
    req_uri =
      %{path: "/"}
      |> Map.merge(conn_uri)
      |> Map.put(:userinfo, nil)

    ws_req_uri =
      case req_uri.path do
        "/" -> %URI{req_uri | port: (req_uri.port || 8545) + 1}
        _ -> req_uri
      end

    ws_req_uri = URI.merge(ws_req_uri, "./ws")

    auth_headers =
      case conn_uri.userinfo do
        "" -> []
        nil -> []
        userinfo -> [{"authorization", "Basic " <> Base.encode64(userinfo)}]
      end

    host_header =
      if ipv4_addr?(req_uri.host) do
        "localhost"
      else
        req_uri.host
      end

    other_headers = [
      {"host", host_header},
      {"user-agent", "covalent/rudder"},
      {"content-type", "application/json"}
    ]

    req_headers = auth_headers ++ other_headers

    %__MODULE__{
      request_uri: URI.to_string(req_uri),
      ws_request_uri: URI.to_string(ws_req_uri),
      request_headers: req_headers
    }
  end

  defp ipv4_addr?(addr) do
    Regex.match?(~r/^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$/, addr)
  end

  defimpl Rudder.RPC.JSONRPC.Client do
    def call(client, rpc_method, rpc_params, opts \\ []) do
      Adapter.call(client.request_uri, client.request_headers, rpc_method, rpc_params, opts)
    end

    def long_call(client, rpc_method, rpc_params) do
      # Adapter.call(client.request_uri, client.request_headers, rpc_method, rpc_params)
      LongCallAdapter.long_call(
        client.ws_request_uri,
        client.request_headers,
        rpc_method,
        rpc_params
      )
    end

    def delete(client, uri_ref) do
      Adapter.delete(URI.merge(client.request_uri, uri_ref), client.request_headers)
    end
  end
end
