defmodule Refiner.RPC.JSONRPC.MessageFormat do
  @spec build_request(:batch | :single, any, any, number) ::
          {binary
           | maybe_improper_list(
               binary | maybe_improper_list(any, binary | []) | byte,
               binary | []
             ), number}
  def build_request(req_shape, rpc_method, rpc_params, req_id \\ 1)

  def build_request(:single, rpc_method, rpc_params, req_id) do
    req = %{
      "jsonrpc" => "2.0",
      "method" => to_string(rpc_method),
      "params" => rpc_params,
      "id" => req_id
    }

    {Jason.encode_to_iodata!(req), req_id + 1}
  end

  def build_request(:batch, rpc_method, rpc_params_list, base_req_id) do
    rpc_method = to_string(rpc_method)

    batch_req =
      Stream.with_index(rpc_params_list)
      |> Stream.map(fn {rpc_params, req_id_offset} ->
        %{
          "jsonrpc" => "2.0",
          "method" => rpc_method,
          "params" => rpc_params,
          "id" => base_req_id + req_id_offset
        }
      end)
      |> Enum.to_list()

    next_base_req_id = base_req_id + length(batch_req)

    {Jason.encode_to_iodata!(batch_req), next_base_req_id}
  end

  @spec parse_response_json(
          binary
          | maybe_improper_list(
              binary | maybe_improper_list(any, binary | []) | byte,
              binary | []
            )
        ) ::
          :invalid_parameters
          | :notfound
          | list
          | {:ok, any}
          | {:rpc_error, any}
          | {:server_error, any, any}
          | {:unknown_error, any, any}
  def parse_response_json(resp_json_iodata) do
    resp_json_iodata
    |> Jason.decode!()
    |> parse_response
  end

  @spec parse_response(maybe_improper_list | map) ::
          :invalid_parameters
          | :notfound
          | list
          | {:ok, any}
          | {:rpc_error, any}
          | {:server_error, any, any}
          | {:unknown_error, any, any}
  def parse_response(%{"error" => %{"code" => code, "message" => msg}}) do
    req_error(code, msg)
  end

  def parse_response(%{"result" => result}) do
    {:ok, result}
  end

  def parse_response(resps) when is_list(resps) do
    Enum.map(resps, &parse_response/1)
  end

  # client may be attempting methods to determine existence, so raise only if invalid syntactically
  @spec req_error(any, any) ::
          :invalid_parameters
          | :notfound
          | {:rpc_error, any}
          | {:server_error, any, any}
          | {:unknown_error, any, any}
  def req_error(-32_700, _), do: raise(ArgumentError, "client sent malformed JSON")
  def req_error(-32_600, _), do: raise(ArgumentError, "invalid request")
  def req_error(-32_601, _), do: :notfound
  def req_error(-32_602, _), do: :invalid_parameters
  def req_error(-32_603, msg), do: {:rpc_error, msg}

  def req_error(code, error_msg) when code >= -32_099 and code <= -32_000 do
    {:server_error, code, error_msg}
  end

  def req_error(code, error_msg) do
    {:unknown_error, code, error_msg}
  end
end
