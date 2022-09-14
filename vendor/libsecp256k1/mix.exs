defmodule LibSECp256k1.MixProject do
  use Mix.Project

  def project, do: [
    app: :libsecp256k1,
    version: "0.1.0",
    elixir: "~> 1.6",
    start_permanent: Mix.env() == :prod,
    deps: deps()
  ]

  def application, do: [
    extra_applications: [:logger, :crypto]
  ]

  defp deps, do: []
end
