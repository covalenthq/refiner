defmodule Rudder.RPC.JSONRPC.HTTPAdapter do
  require Logger

  @http_retries 5

  def delete(req_uri, req_headers) do
    Finch.build(
      :delete,
      req_uri,
      req_headers
    )
    |> Finch.request(Rudder.Finch)
  end

  def call(req_uri, req_headers, rpc_method, rpc_params, opts) do
    with_keepalive = Keyword.get(opts, :keepalive, true)
    request_timeout = Keyword.get(opts, :request_timeout, 1_200_000)

    req_rpc_method = to_string(rpc_method)

    req_body =
      Jason.encode_to_iodata!(%{
        "jsonrpc" => "2.0",
        "method" => req_rpc_method,
        "params" => rpc_params,
        "id" => 1
      })

    request =
      Finch.build(
        :post,
        req_uri,
        req_headers,
        req_body,
        [
          {"request-timeout", request_timeout},
          {"follow-redirect", true},
          {"pool-group", :rpc_pool}
        ]
      )

    with {:ok, jsonrpc_resps} <-
           submit_and_decode_http_req_with_retry(request, @http_retries),
         jsonrpc_results <- Enum.map(jsonrpc_resps, &decode_jsonrpc_resp/1),
         [jsonrpc_result] <- collate_jsonrpc_results(jsonrpc_results) do
      jsonrpc_result
    else
      err ->
        err
    end
  end

  def collate_jsonrpc_results(jsonrpc_results) do
    Enum.sort(jsonrpc_results)
    |> Enum.map(&elem(&1, 1))
  end

  defp submit_and_decode_http_req_with_retry(req_body, retries_left)

  defp submit_and_decode_http_req_with_retry(_req_body, 0),
    do: raise(Rudder.RPCError, "retries exceeded")

  defp submit_and_decode_http_req_with_retry(req_body, retries_left) do
    case decode_http_resp(Finch.request(req_body, Rudder.Finch)) do
      :connection_closed ->
        submit_and_decode_http_req_with_retry(req_body, retries_left - 1)

      :timeout ->
        submit_and_decode_http_req_with_retry(req_body, retries_left - 1)

      :gateway_error ->
        Process.sleep(10_000)
        submit_and_decode_http_req_with_retry(req_body, retries_left)

      :overload ->
        Process.sleep(10_000)
        submit_and_decode_http_req_with_retry(req_body, retries_left)

      :rate_limited ->
        Process.sleep(5000)
        submit_and_decode_http_req_with_retry(req_body, retries_left - 1)

      other ->
        other
    end
  end

  def decode_http_resp({:ok, %{status: http_resp_code, body: http_resp_body}})
      when http_resp_code >= 200 and http_resp_code < 300 do
    case Jason.decode!(http_resp_body) do
      %{"error" => %{"code" => batch_error_code, "message" => batch_error_msg}} ->
        batch_error({http_resp_code, batch_error_code}, batch_error_msg)

      jsonrpc_resp_batch when is_list(jsonrpc_resp_batch) ->
        {:ok, jsonrpc_resp_batch}

      jsonrpc_resp_single when is_map(jsonrpc_resp_single) ->
        {:ok, [jsonrpc_resp_single]}
    end
  end

  def decode_http_resp({:ok, %{status: http_resp_code, body: http_resp_body}}),
    do: batch_error(http_resp_code, http_resp_body)

  def decode_http_resp({:error, %Finch.Error{reason: :request_timeout}}),
    do: :timeout

  def decode_http_resp({:error, %Finch.Error{reason: :normal}}),
    do: :connection_closed

  def decode_http_resp({:error, %Mint.TransportError{reason: :closed}}),
    do: :connection_closed

  def decode_http_resp({:error, %Finch.Error{reason: {:stop, {:goaway, _, _, _}, _}}}),
    do: :connection_closed

  def decode_http_resp({:error, %Finch.Error{reason: {:stream_error, :internal_error, _}}}),
    do: :connection_closed

  def decode_http_resp({:error, %Finch.Error{reason: :closed}}),
    do: :connection_closed

  def decode_http_resp({:error, %Finch.Error{reason: {:closed, _}}}),
    do: :connection_closed

  def decode_http_resp({:error, %Finch.Error{} = e}),
    do: raise(Rudder.RPCError, e)

  def decode_http_resp({:error, %Mint.TransportError{reason: :econnrefused} = e}),
    do: raise(Rudder.RPCError, e)

  def decode_jsonrpc_resp(%{"id" => seq, "error" => %{"code" => code, "message" => msg}}),
    do: {seq, req_error(code, msg)}

  def decode_jsonrpc_resp(%{"id" => seq, "result" => result}),
    do: {seq, {:ok, result}}

  # raise on logic errors; return on environment errors; return if unsure
  def batch_error(401, _), do: :forbidden
  def batch_error(404, _), do: :notfound
  def batch_error(500, error_msg), do: {:server_error, 500, error_msg}
  def batch_error(502, _), do: :gateway_error
  def batch_error(503, _), do: :overload
  def batch_error(524, _), do: :overload
  def batch_error({_, -32700}, _), do: raise(Rudder.RPCError, "client sent malformed JSON")
  def batch_error({_, -32600}, _), do: raise(Rudder.RPCError, "invalid request")
  def batch_error({_, -32601}, _), do: raise(Rudder.RPCError, "RPC endpoint not available")
  def batch_error({_, -32602}, e), do: raise(Rudder.RPCError, {"invalid parameters", e})
  def batch_error({_, -32603}, msg), do: raise(Rudder.RPCError, {"internal JSON-RPC error", msg})

  def batch_error({_, code}, error_msg) when code >= -32099 and code <= -32000 do
    {:server_error, code, error_msg}
  end

  def batch_error({_, code}, error_msg) do
    {:unknown_error, code, error_msg}
  end

  def batch_error(429, _msg) do
    :rate_limited
  end

  def batch_error(400, ""), do: :gateway_error

  def batch_error(code, msg) when code >= 400 and code < 500 do
    raise Rudder.RPCError, {:client_error, code, msg}
  end

  def batch_error(code, msg) when code >= 500 and code < 600 do
    {:server_error, msg}
  end

  def batch_error(code, msg), do: {:unknown_error, code, msg}

  # client may be attempting methods to determine existence, so raise only if invalid syntactically
  def req_error(-32700, _), do: raise(Rudder.RPCError, "client sent malformed JSON")
  def req_error(-32600, _), do: raise(Rudder.RPCError, "invalid request")
  def req_error(-32601, _), do: :notfound
  def req_error(-32602, e), do: {:invalid_parameters, e}
  def req_error(-32603, msg), do: {:rpc_error, msg}

  def req_error(code, error_msg) when code >= -32099 and code <= -32000 do
    {:server_error, code, error_msg}
  end

  def req_error(code, error_msg) do
    {:unknown_error, code, error_msg}
  end
end
