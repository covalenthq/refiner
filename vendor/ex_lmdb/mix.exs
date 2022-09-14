defmodule ExLMDB.Mixfile do
  use Mix.Project

  def project, do: [
    app: :ex_lmdb,
    version: "0.1.0",
    elixir: "~> 1.7",
    deps: deps()
  ]

  def application, do: [
    applications: []
  ]

  defp deps, do: [
  ]
end
