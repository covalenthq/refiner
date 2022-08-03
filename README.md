# Rudder

Rudder is the rule engine processor and supervisor for the refiner process in the Covalent Network and further it scalably and securely captures block specimens and their respective transformations.

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `rudder` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:rudder, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at <https://hexdocs.pm/rudder>.

# Transform

```
git submodule update --init --recursive
cd rudder/bsp-agent
git checkout scripts/extractor-with-files
go build scripts/extractor.go && mv extractor ../
```
