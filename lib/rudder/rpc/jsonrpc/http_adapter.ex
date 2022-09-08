defmodule Rudder.RPC.JSONRPC.HTTPAdapter do
  require Logger

  @http_retries 5

  def download(req_uri, req_headers, io_device) do
    download_task = Task.async(Downstream.Download, :stream, [io_device])

    own_host = :proplists.get_value("host", req_headers)

    req_headers =
      case req_uri.host do
        ^own_host -> req_headers
        _other_host -> []
      end

    HTTPoison.get!(req_uri, req_headers, hackney: [pool: false], stream_to: download_task.pid)

    {:ok, http_resp} = Task.await(download_task, :infinity)

    case http_resp do
      %Downstream.Response{status_code: s} = resp when s >= 200 and s < 400 -> {:ok, resp}
      %Downstream.Error{} = err -> {:error, err}
    end
  end

  def fetch_digest(req_uri, req_headers) do
    own_host = :proplists.get_value("host", req_headers)

    req_headers =
      case req_uri.host do
        ^own_host -> req_headers
        _other_host -> []
      end

    case HTTPoison.get(req_uri, req_headers) do
      {:ok, %HTTPoison.Response{body: digest_asc}} ->
        digest =
          String.trim(digest_asc)
          |> Base.decode16!(case: :mixed)

        {:ok, digest}

      other ->
        other
    end
  end

  def delete(req_uri, req_headers) do
    HTTPoison.delete(req_uri, req_headers)
  end

  def call(req_uri, req_headers, rpc_method, rpc_params, opts) do
    case batch_call(req_uri, req_headers, rpc_method, [rpc_params], Keyword.put_new(opts, :max_batch_size, 1)) do
      {:ok, [resp]} -> resp
      batch_error -> batch_error
    end
  end

  def batch_call(req_uri, req_headers, rpc_method, rpc_params_stream, opts) do
    max_batch_size = Keyword.get(opts, :max_batch_size, 100)
    with_keepalive = Keyword.get(opts, :keepalive, true)
    request_timeout = Keyword.get(opts, :request_timeout, 1_200_000)

    req_rpc_method = to_string(rpc_method)

    req_bodies =
      Stream.with_index(rpc_params_stream)
      |> Stream.map(fn {rpc_params, i} ->
        %{
          "jsonrpc" => "2.0",
          "method" => req_rpc_method,
          "params" => rpc_params,
          "id" => i + 1
        }
      end)

    req_bodies =
      case max_batch_size do
        1 ->
          req_bodies

        n when n > 1 ->
          Stream.chunk_every(req_bodies, n)
      end

    req_bodies = Enum.to_list(req_bodies)

    send_req_body_fn =
      if with_keepalive do
        fn req_body ->
          MachineGun.post(
            req_uri,
            Jason.encode_to_iodata!(req_body),
            req_headers,
            %{
              request_timeout: request_timeout,
              follow_redirect: true,
              pool_group: :rpc_pool
            }
          )
        end
      else
        fn req_body ->
          HTTPoison.post(
            req_uri,
            Jason.encode_to_iodata!(req_body),
            req_headers,
            follow_redirect: true,
            timeout: request_timeout,
            recv_timeout: request_timeout,
            hackney: [pool: false, ssl: [verify: :verify_none]]
          )
        end
      end

    submit_and_decode_http_reqs(req_bodies, send_req_body_fn, @http_retries, [])
  end

  defp submit_and_decode_http_reqs([], _send_req_body_fn, _use_retries, acc) do
    jsonrpc_results =
      Enum.reverse(acc)
      |> Enum.map(&List.wrap/1)
      |> Enum.concat()

    {:ok, jsonrpc_results}
  end

  defp submit_and_decode_http_reqs([req_body | rest], send_req_body_fn, use_retries, acc) do
    with {:ok, jsonrpc_resps} <- submit_and_decode_http_req_with_retry(req_body, send_req_body_fn, use_retries),
         jsonrpc_results <- Enum.map(jsonrpc_resps, &decode_jsonrpc_resp/1),
         ordered_jsonrpc_results <- collate_jsonrpc_results(jsonrpc_results) do
      submit_and_decode_http_reqs(rest, send_req_body_fn, use_retries, [ordered_jsonrpc_results | acc])
    else
      err ->
        err
    end
  end

  defp submit_and_decode_http_req_with_retry(req_body, send_req_body_fn, retries_left)

  defp submit_and_decode_http_req_with_retry(_req_body, _send_req_body_fn, 0),
    do: raise(Rudder.RPCError, "retries exceeded")

  defp submit_and_decode_http_req_with_retry(req_body, send_req_body_fn, retries_left) do
    case decode_http_resp(send_req_body_fn.(req_body)) do
      :connection_closed ->
        submit_and_decode_http_req_with_retry(req_body, send_req_body_fn, retries_left - 1)

      :timeout ->
        submit_and_decode_http_req_with_retry(req_body, send_req_body_fn, retries_left - 1)

      :gateway_error ->
        Process.sleep(10_000)
        submit_and_decode_http_req_with_retry(req_body, send_req_body_fn, retries_left)

      :overload ->
        Process.sleep(10_000)
        submit_and_decode_http_req_with_retry(req_body, send_req_body_fn, retries_left)

      :rate_limited ->
        Process.sleep(5000)
        submit_and_decode_http_req_with_retry(req_body, send_req_body_fn, retries_left - 1)

      other ->
        other
    end
  end

  def decode_http_resp({:ok, %{status_code: http_resp_code, body: http_resp_body}})
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

  def decode_http_resp({:ok, %{status_code: http_resp_code, body: http_resp_body}}),
    do: batch_error(http_resp_code, http_resp_body)

  def decode_http_resp({:error, %MachineGun.Error{reason: :request_timeout}}),
    do: :timeout

  def decode_http_resp({:error, %MachineGun.Error{reason: :normal}}),
    do: :connection_closed

  def decode_http_resp({:error, %MachineGun.Error{reason: {:stop, {:goaway, _, _, _}, _}}}),
    do: :connection_closed

  def decode_http_resp({:error, %MachineGun.Error{reason: {:stream_error, :internal_error, _}}}),
    do: :connection_closed

  def decode_http_resp({:error, %MachineGun.Error{reason: :closed}}),
    do: :connection_closed

  def decode_http_resp({:error, %MachineGun.Error{reason: {:closed, _}}}),
    do: :connection_closed

  def decode_http_resp({:error, %MachineGun.Error{} = e}),
    do: raise(Rudder.RPCError, e)

  def decode_http_resp({:error, %HTTPoison.Error{reason: :timeout}}),
    do: :timeout

  def decode_http_resp({:error, %HTTPoison.Error{} = e}),
    do: raise(Rudder.RPCError, e)

  def decode_jsonrpc_resp(%{"id" => seq, "error" => %{"code" => code, "message" => msg}}),
    do: {seq, req_error(code, msg)}

  def decode_jsonrpc_resp(%{"id" => seq, "result" => result}),
    do: {seq, {:ok, result}}

  def collate_jsonrpc_results(jsonrpc_results) do
    Enum.sort(jsonrpc_results)
    |> Enum.map(&elem(&1, 1))
  end

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

  # for aurora
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
