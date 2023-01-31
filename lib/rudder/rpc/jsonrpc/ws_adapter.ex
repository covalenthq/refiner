defmodule Rudder.RPC.JSONRPC.WSAdapter do
  alias Rudder.RPC.JSONRPC.MessageFormat

  use WebSockex
  require Logger

  def long_call(req_uri, req_headers, rpc_method, rpc_params) do
    req_rpc_method = to_string(rpc_method)

    req_body =
      Jason.encode!(%{
        "jsonrpc" => "2.0",
        "method" => req_rpc_method,
        "params" => rpc_params,
        "id" => 1
      })

    req_headers = :proplists.delete("host", req_headers)

    sock_opts =
      WebSockex.Conn.new(req_uri,
        extra_headers: req_headers,
        handle_initial_conn_failure: true
      )

    attempt_long_call(sock_opts, req_body, 30, 500)
  end

  defp attempt_long_call(_sock_opts, _req_body, 0, _wait), do: {:remote, :closed}

  defp attempt_long_call(sock_opts, req_body, attempts_left, wait_after) do
    {:ok, socket} = WebSockex.Conn.open_socket(sock_opts)
    {:ok, ts} = WebSockex.start_link(socket, __MODULE__, self())

    WebSockex.send_frame(ts, {:binary, req_body})

    receive do
      {:ws_error, {:remote, :closed}} ->
        Process.sleep(wait_after + :rand.uniform(500))
        attempt_long_call(sock_opts, req_body, attempts_left - 1, wait_after * 2)

      {:ws_error, {:remote, 1000, ""}} ->
        Process.sleep(wait_after + :rand.uniform(500))
        attempt_long_call(sock_opts, req_body, attempts_left - 1, wait_after * 2)

      {:ws_error, ws_err} ->
        ws_err

      {:ws_resp, {_type, ws_resp}} ->
        case MessageFormat.parse_response_json(ws_resp) do
          {:server_error, -32_000, "RLP tracing in-use by another client"} ->
            Process.sleep(wait_after + :rand.uniform(500))
            attempt_long_call(sock_opts, req_body, attempts_left - 1, trunc(wait_after * 1.1))

          other_resp ->
            other_resp
        end
    end
  end

  def handle_connect(_conn, state) do
    {:ok, state}
  end

  def handle_frame(other_frame, controller_pid) do
    send(controller_pid, {:ws_resp, other_frame})
    {:close, controller_pid}
  end

  def handle_disconnect(%{reason: {:local, :normal}}, controller_pid) do
    {:ok, controller_pid}
  end

  def handle_disconnect(%{reason: reason}, controller_pid) do
    Logger.info("ws close with reason: #{inspect(reason)}")
    send(controller_pid, {:ws_error, reason})
    {:ok, controller_pid}
  end
end
