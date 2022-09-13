defmodule Exleveldb.Mixfile do
  use Mix.Project

  def project, do: [
    app: :exleveldb,
    version: "0.14.0",
    elixir: "~> 1.7",
    deps: deps()
  ]

  def application, do: [
    applications: []
  ]

  defp deps, do: [
  ]
end
