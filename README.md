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

## Block Specimen Transform (avro binary specimen -> json specimen)

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

 iex(3)> Rudder.build_sync("./rules/rules.json")
%{
  "args" => "--binary-file-path './bin/block-specimens/' --codec-path './priv/schemas/block-ethereum.avsc' --indent-json 0 --output-file-path './out/block-results/'",
  "exec" => "./evm/extractor",
  "input" => "./bin/block-specimens/",
  "output" => "./out/block-results/",
  "rule" => "./evm/extractor --binary-file-path './bin/block-specimens/' --codec-path './priv/schemas/block-ethereum.avsc' --indent-json 0 --output-file-path './out/block-results/'"
}
%Porcelain.Result{
  err: nil,
  out: "bsp-extractor command line config:  [binary-file-path:\"./bin/block-specimens/\" codec-path:\"./priv/schemas/block-ethereum.avsc\" indent-json:\"0\" output-file-path:\"./out/block-results/\"]\n\nfile:  out/block-results/1-15127599-replica-0x167a4a9380713f133aa55f251fd307bd88dfd9ad1f2087346e1b741ff47ba7f5-specimen.json bytes:  1563265\n\nfile:  out/block-results/1-15127600-replica-0x14a2d5978dcde0e6988871c1a246bea31e44f73467f7c242f9cd19c30cd5f8b1-specimen.json bytes:  2761078\n\nfile:  out/block-results/1-15127601-replica-0x4757d9272c0f4c5f961667d43265123d22d7459d63f2041866df2962758c6070-specimen.json bytes:  3693996\n\nfile:  out/block-results/1-15127602-replica-0xce9ed851812286e05cd34684c9ce3836ea62ebbfc3764c8d8a131f0fd054ca35-specimen.json bytes:  4492753\n\nfile:  out/block-results/1-15127603-replica-0x5150c04d372839f7569f8d208514fd145d2fd450e13e6606bfc74b29aaadcbbf-specimen.json bytes:  818559\n\nfile:  out/block-results/1-15127603-replica-0x5fb7802a8b0f1853bd3e9e8a8646df603e6c57d8da7df62ed46bfec1a6a074c4-specimen.json bytes:  1684665\n\nfile:  out/block-results/1-15127604-replica-0xd3a4b3af87f6e43dcba7c663a4070445c22a84b7bb525046f0abd9678ec08c02-specimen.json bytes:  4839253\n\nfile:  out/block-results/1-15127605-replica-0xa7874fd4e10d6c0cc67a83c63854c08d819e08fec9590b4fa0add54970ef2841-specimen.json bytes:  3383928\n\nfile:  out/block-results/1-15127606-replica-0xeccf0cfc7d2d015de85f127039871da3f060086ad19b9a1468c9b6bb6b91e51e-specimen.json bytes:  1237007\n\nfile:  out/block-results/1-15127607-replica-0x8fecdc775c3454a95707b317d8954a5685e25e7323d988d09aea23468a8823ec-specimen.json bytes:  2914982\n\nfile:  out/block-results/1-15127608-replica-0xf52b8075ee753a9391d491b2c6bd72d59abc828c3e80fb07c7ee4775aa826056-specimen.json bytes:  1422270\n\nfile:  out/block-results/1-15127609-replica-0x9f0e6b925f13491ad303a9ba1789ec97bbea1c3f267bd6a91d081304a9a27875-specimen.json bytes:  3568478\n\nfile:  out/block-results/1-15127610-replica-0x47da4d59dbbe7434cd442718d7bd39560ea1b43a22eba9d92094e6b5b7703ad9-specimen.json bytes:  2210605\n\nfile:  out/block-results/1-15127611-replica-0xaff0a12c223cedbbea7a4e5454268cb00dd9da8ecbbd2a3890a799368df0a37a-specimen.json bytes:  1411556\n\nfile:  out/block-results/1-15127612-replica-0x6bd6290ede28a61c1427f2beed568fca09eef973b9a07c7f6e3b8afce8b277dc-specimen.json bytes:  4981049\n\nfile:  out/block-results/1-15127613-replica-0x9a8945013569749158565b2428962b15be43fb5b7401ee42d9b997962191b850-specimen.json bytes:  2933406\n\nfile:  out/block-results/1-15127614-replica-0xb0ce37928886daf2f1a27de119920bff38fabf27ee278302105c0229bbfb1b3d-specimen.json bytes:  271212\n\nfile:  out/block-results/1-15127615-replica-0x9fb0b947ebb4a3fb7cf82b11836d896fc2c12f02aa7325e0c746fabc3928dc70-specimen.json bytes:  1171409\n\nfile:  out/block-results/1-15127616-replica-0xaebea9c46b75eca6d61e2a25c07c9a560ba49a1b9e380fccfff4ab6bdb87c770-specimen.json bytes:  1491136\n\nfile:  out/block-results/1-15127617-replica-0xac8b8454b9ef91e3b66662a3060af0c50a958b329c4b74af8fa5ddc859851a61-specimen.json bytes:  1869991\n\nfile:  out/block-results/1-15127618-replica-0x6dbe6fb3c1141520b6f32c3ca26cccc9e1d7dba365aee93967a36ac91671ea33-specimen.json bytes:  3036349\n\nfile:  out/block-results/1-15127619-replica-0x204f962fd3ea09435883a857a972624c8c3ecd13b2d06d6de3d01844adb8c9c6-specimen.json bytes:  3486825\n\nfile:  out/block-results/1-15127620-replica-0x29c061b004e49b60a4ea8307b65a741b6015e9d2617d65044c49867ee6c6c18f-specimen.json bytes:  5705823\n\nfile:  out/block-results/1-15127621-replica-0xf4b610cba79149defb7e53f9308e654d94b3cbeb6530b385500b6b23acb55853-specimen.json bytes:  3657869\n\nfile:  out/block-results/1-15127622-replica-0x983aef3f55148d274e17f5d3f2285b88eedc60742763c012c7726f9f4a955028-specimen.json bytes:  5570971\n\nfile:  out/block-results/1-15127623-replica-0x1f05cff4bed40e0eff38a3ee387b4abff3332a6c805a3a53aca460997d16adc4-specimen.json bytes:  2177419\n\nfile:  out/block-results/1-15127624-replica-0x087ea6238cf4dfa64342c31eca77635c2cb2e166c462a6ea843923a7f7a72f8a-specimen.json bytes:  444069\n\nfile:  out/block-results/1-15127625-replica-0x52bffc579869912debc5dc59ce35ae4f9d" <> ...,
  status: 0
}
  ```

This should generate the JSON output specimen file (results) to `./out` directory as seen above.

3. View generated/transformed files from binary block specimens

  ```bash
    cd out/block-results
    cat 1-15127599-replica-0x167a4a9380713f133aa55f251fd307bd88dfd9ad1f2087346e1b741ff47ba7f5-specimen.json
  ```

## Block Specimen Transform - Concurrent Extractor

1. In the above process we used a sync method to extract all the files in a given directory using a binary generated by Go code

2. Here we extract the files directly async by using a file stream, spawing a decode process for each file separately and using the AVRO library `avrora`

3. It can be tested with the following steps ()
  a. read a binary block specimen file
  b. start the avro client
  c. decode to json map using the `decode_plain` avrora fn

```elixir

iex(4)> {:ok, file0} = File.read("./bin/block-specimens/1-15127599-replica-0x167a4a9380713f133aa55f251fd307bd88dfd9ad1f2087346e1b741ff47ba7f5")
{:ok,
 <<2, 132, 1, 48, 120, 56, 102, 56, 53, 56, 51, 53, 54, 99, 52, 56, 98,
   50, 55, 48, 50, 50, 49, 56, 49, 52, 102, 56, 99, 49, 98, 50, 101,
   98, 56, 48, 52, 97, 53, 102, 98, 100, 51, 97, 99, 55, 55, 55, ...>>}

iex(5)> {:ok, pid} = Rudder.Avro.Client.start_link()
{:ok, #PID<0.333.0>}

iex(6)> {:ok, decoded0} = Rudder.Avro.Client.decode_plain(file0, schema_name: "block-ethereum") [debug] reading schema `block-ethereum` from the file /Users/pranay/Documents/covalent/elixir-projects/rudder/priv/schemas/block-ethereum.avsc
{:ok,
 %{
   "codecVersion" => 0.2,
   "elements" => 1,
   "endBlock" => 15127599,
   "replicaEvent" => [
     %{
       "data" => %{
         "Hash" => "0x8f858356c48b270221814f8c1b2eb804a5fbd3ac7774b527f2fe0605be03fb37",
```

4. Please note the above extractor process only extract a single specimen

5. A stream of specimens files can be passed instead to the avro decode process

## Block Specimen Session Event Listener

In order to run the listener you need to fork ethereum node, run a script to add the operators and a script that mocks block specimen submissions and session finalizations using the docker:

1. Add `.env` file.

2. Inside `.env` add ERIGON_NODE variable and replace the node's url with yours:

```bash
export ERIGON_NODE="erigon.node.url"
```

3. Inside a terminal got to the rudder folder and run: 

```bash 
docker compose --env-file ".env" -f "docker-compose-local.yml" up --remove-orphans
```

4. Inside a separate terminal run:

```bash
docker exec -it eth-node /bin/sh  -c "cd /usr/src/app; npm run docker:run";
```

5. Inside a third terminal navigate to the `rudder` folder and run:

```elixir
iex -S mix 
Rudder.ProofChain.BlockSpecimenEventListener.start()
```

## ProofChain Contract Interactor 

In order to run the interactor you need to fork ethereum node and run a script to add the operators using the docker:

1. Add `.env` file.

2. Inside `.env` add ERIGON_NODE variable and replace the node's url with yours:

```bash
export ERIGON_NODE="erigon.node.url"
```

3. Inside a terminal got to the rudder folder and run: 

```bash 
docker compose --env-file ".env" -f "docker-compose-local.yml" up --remove-orphans
```

4. Inside a second terminal navigate to the `rudder` folder and run:

```elixir
iex -S mix 
```

then
```
Rudder.ProofChain.Interactor.test_submit_block_result_proof(block_height)
```
or
```
Rudder.ProofChain.Interactor.submit_block_result_proof(chain_id, block_height, block_specimen_hash, block_result_hash, url) 
```