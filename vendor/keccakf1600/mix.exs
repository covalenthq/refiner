defmodule Keccakf1600.MixProject do
  use Mix.Project

  def project, do: [
    app: :keccakf1600,
    version: "0.1.0",
    elixir: "~> 1.6",
    start_permanent: Mix.env() == :prod,
    deps: deps()
  ]

  def application, do: [
    extra_applications: [:logger]
  ]

  defp deps, do: [
    {:ex_keccak, "~> 0.2.0"}
  ]
end
