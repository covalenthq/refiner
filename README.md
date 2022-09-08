# Rudder

Rudder is the rule engine processor and supervisor for the refiner process in the Covalent Network and further it scalably and securely captures block specimens and their respective transformations.

## Install

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

## Transform

1. Generate transformer plugin / binary.

  ```bash
    git submodule update --init --recursive
    cd rudder/bsp-agent
    git checkout scripts/extractor-with-files
    go build scripts/extractor.go && mv extractor ../evm/
  ```

2. Apply transform rules.

  ```elixir
    iex -S mix

    Erlang/OTP 25 [erts-13.0] [source] [64-bit] [smp:8:8] [ds:8:8:10] [async-threads:1] [jit:ns] [dtrace]
    Generated rudder app
    Interactive Elixir (1.13.4) - press Ctrl+C to exit (type h() ENTER for help)

    iex(1)> Rudder.build("rules/rules.json")
    %Porcelain.Result{
    err: nil,
    out: "bsp-extractor command line config:  [binary-file-path:\"./ bin/block-specimens/\" codec-path:\"./bsp-agent/codec/block-ethereum.avsc\" indent-json:\"0\" output-file-path:\"./out/block-results/\"]\n\nfile:  out/block-results/1-15127599-replica-0x167a4a9380713f133aa55f251fd307bd88dfd9ad1f2087346e1b741ff47ba7f5-specimen.json bytes:  1563265\n\nfile:  out/block-results/1-15127600-replica-0x14a2d5978dcde0e6988871c1a246bea31e44f73467f7c242f9cd19c30cd5f8b1-specimen.json bytes:  2761078\n\nfile:  out/block-results/1-15127601-replica-0x4757d9272c0f4c5f961667d43265123d22d7459d63f2041866df2962758c6070-specimen.json bytes:  3693996\n\nfile:  out/block-results/
    status: 0
    }
  ```

This should generate the JSON output specimen file (results) to `./out` directory as seen above.

3. View generated/transformed files from binary block specimens

  ```bash
    cd out/block-results
    cat 1-15127599-replica-0x167a4a9380713f133aa55f251fd307bd88dfd9ad1f2087346e1b741ff47ba7f5-specimen.json
  ```

## Block Specimen Session Event Listener
In order to run the listener you need to fork ethereum node, run a script to add the operators and a script that mocks block specimen submissions and session finalizations using the docker:
1. Add `.env` file.
2. Inside `.env` add ERIGON_NODE variable and replace the node's url with yours:
```
export ERIGON_NODE="erogone.node.url"
```
3. Inside a terminal got to the rudder folder and run: 
``` 
docker compose --env-file ".env" -f "docker-compose-local.yml" up --remove-orphans
```
4. Inside a separate terminal run:
```
docker exec -it eth-node /bin/sh  -c "cd /usr/src/app; npm run docker:run";
```
5. Inside a third terminal navigate to the `rudder` folder and run:
```
iex -S mix 
Rudder.ProofChain.BlockSpecimenEventListener.start()
```
