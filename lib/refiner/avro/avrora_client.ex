defmodule Refiner.Avro.Client do
  use Avrora.Client,
    otp_app: :refiner,
    registry_url: "http://localhost:8081",
    registry_auth: {:basic, ["username", "password"]},
    schemas_path: "priv/schemas/",
    registry_schemas_autoreg: false,
    convert_null_values: false,
    convert_map_to_proplist: false,
    names_cache_ttl: :infinity
end
