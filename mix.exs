defmodule Rudder.MixProject do
  use Mix.Project

  def project do
    [
      app: :rudder,
      version: "0.1.0",
      elixir: "~> 1.13.4",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end
  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      applications: [:ethereumex, :eth_contract],
      extra_applications: [:logger, :runtime_tools],
      mod: {Rudder.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:httpoison, "~> 1.6"},
      {:poison, "~> 3.1"},
      {:jason, "~> 1.1"},
      {:broadway, "~> 1.0", override: true},
      {:web3, "~> 0.1.2"},
      {:eth_contract, "~> 0.1.0"},
      {:off_broadway_redis, "~> 0.4.3"},
      {:abi, "~> 0.1.13"},
      {:ethereumex, "~> 0.9", override: true},
      {:cors_plug, "~> 2.0"},
      {:phoenix, "~> 1.4.9"},
      {:phoenix_pubsub, "~> 1.1"},
      {:gettext, "~> 0.11"},
      {:plug_cowboy, "~> 2.0"},
      {:ranch, "~> 1.7.1",
       [env: :prod, hex: "ranch", repo: "hexpm", optional: false, override: true]}
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
    ]
  end
end
