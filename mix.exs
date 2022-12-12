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
      extra_applications: [:logger_file_backend, :runtime_tools, :poison, :avrora, :porcelain],
      mod: {Rudder.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:poison, "~> 5.0"},
      {:porcelain, "~> 2.0"},
      {:broadway, "~> 1.0", override: true},
      # {:erlexec, "~> 2.0"},
      {:off_broadway_redis, "~> 0.4.3"},
      {:cors_plug, "~> 2.0"},
      {:phoenix, "~> 1.4.9"},
      {:phoenix_pubsub, "~> 1.1"},
      {:gettext, "~> 0.11"},
      {:plug_cowboy, "~> 2.0"},
      {:rustler, "~> 0.26.0", override: true},
      {:ranch, "~> 1.7.1",
       [env: :prod, hex: "ranch", repo: "hexpm", optional: false, override: true]},

      # parsing and encoding
      {:abi,
       github: "tsutsu/ethereum_abi",
       branch: "feature-parse-events-from-abi-specifications",
       override: true},
      {:ex_secp256k1, "~> 0.6.0"},
      {:ex_keccak, "~> 0.3.0", override: true},
      {:mnemonic, "~> 0.3"},
      {:ex_rlp, "~> 0.5.4", override: true},
      {:jason, "~> 1.3"},

      # architecture
      {:confex, "~> 3.3"},
      {:poolboy, "~> 1.5"},

      # networking
      {:certifi, "~> 2.9", override: true},
      {:finch, "~> 0.13.0"},
      {:downstream, "~> 1.0"},
      {:websockex, "~> 0.4.3"},
      {:multipart, "~> 0.3.1"},

      # static code analysis
      {:dialyxir, "~> 1.0", only: [:dev], runtime: false},
      {:credo, "~> 1.6", only: [:dev, :test], runtime: false},

      # avro tools
      {:avrora, "~> 0.21"},

      # logging
      {:logger_file_backend, "~> 0.0.12"},
      {:etfs, "~> 0.1.5"}
    ]
  end
end
