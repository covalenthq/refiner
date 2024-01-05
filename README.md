[<img src=./docs/covalent-1.png>](https://www.covalenthq.com/docs/cqt-network/covalent-network-whitepaper/)

<div align="center">
  <a href="https://github.com/covalenthq/rudder/releases/latest">
    <img alt="Version" src="https://img.shields.io/github/v/release/covalenthq/rudder" />
  </a>
  <a href="https://github.com/covalenthq/rudder/blob/main/LICENSE">
    <img alt="License: " src="https://img.shields.io/badge/license-apache-green" />
  </a>
  <a href="http://covalenthq.com/discord">
    <img alt="Discord" src="https://img.shields.io/badge/discord-join%20chat-blue.svg" />
  </a>
    <a href="http://covalenthq.com/discord">
    <img alt="Discord" src="https://img.shields.io/discord/715804406842392586.svg" />
  </a>
</div>
<div align="center">
  <a href="https://github.com/covalenthq/rudder/actions/workflows/compile-format.yaml?query=branch%3Amain+workflow%3Acompile-format">
    <img alt="Linter Status" src="https://github.com/covalenthq/rudder/actions/workflows/compile-format.yaml/badge.svg?branch=main" />
  </a>
  <a href="https://github.com/covalenthq/rudder/actions/workflows/docker-ci-test.yaml?query=branch%3Amain+workflow%3Adocker-ci-test">
    <img alt="CI Tests Status" src="https://github.com/covalenthq/rudder/actions/workflows/docker-ci-test.yaml/badge.svg?branch=main" />
  </a>
  <a href="https://github.com/covalenthq/rudder/actions/workflows/hadolint.ymlquery=branch%3Amain+workflow%3Ahadolint">
    <img alt="Docker Lint Status" src="https://github.com/covalenthq/rudder/actions/workflows/hadolint.yml/badge.svg?branch=main" />
  </a>
    <a href="https://codecov.io/github/covalenthq/rudder" > 
 <img src="https://codecov.io/github/covalenthq/rudder/graph/badge.svg?token=u6d8eqXldF"/> 
 </a>
  <a href="https://twitter.com/@Covalent_HQ">
    <img alt="Twitter Follow Covalent" src="https://img.shields.io/twitter/follow/Covalent_HQ"/>
  </a>
</div>

# Rudder

- [Introduction](#introduction)
  - [Raison d'être](#raison-dêtre)
- [Architecture](#architecture)
- [Resources](#resources)
  - [Additional Resources](#additional-resources)
- [Requirements](#requirements)
- [Run with Docker Compose](#run-with-docker-compose)
  - [Environment](#environment)
  - [Pull](#pull)
  - [Run](#docker-run)
  - [Monitor](#monitor)
- [Build & Run From Source](#build-from-source)
  - [Linux x86_64](#linux-x86_64-ubuntu-2204-lts-install-dependencies)
  - [Environment](#env-vars)
  - [Run](#source-run)
  - [Monitor](#monitor)
- [Troubleshooting](#troubleshooting)
  - [Bugs Reporting & Contributions](#bugs-reporting-contributions)
- [Scripts](#scripts)
- [Appendix](#appendix)

## <span id="rudder_intro">Introduction</span>

![Layers](./docs/network-layers.png)

Refiner is the primary Block Specimen data processing framework, the purpose of which is data transformation and various block data representations.

Generally, the Refiner can perform arbitrary transformations over any binary block specimen file concurrently. This enables simultaneous data indexing, with any consumer of the data slicing and dicing the data as they see fit. Such concurrent execution of Ethereum blocks (via block specimens) makes it possible to trace, enrich or analyze blockchain data at an unprecedented rate with no sequential bottlenecks (provided each block specimen is its own independent entity and available at a decentralized content address!).

The [Refiner Whitepaper](https://www.covalenthq.com/docs/cqt-network/refiner-whitepaper/) goes into detail on its purpose and mission.

Among many of the Refiner's outputs feasible, the Block Result is one. The block result is a one-to-one representation of block data returned from an RPC call to a blockchain node along with the artifacts of block and tx execution like transaction `receipts`. The source of the block result, the block specimen, captures a few extra fields like the [State Specimen](https://github.com/covalenthq/bsp-agent#state-specimen) and `senders` etc. This full specification and its requirement are described well in the [BSP whitepaper](https://www.covalenthq.com/static/documents/Block%20Specimen%20Whitepaper%20V1.2.pdf).

Running the Refiner stack involves running three main pieces of CQT Network OS infrastructure,  [`rudder`](https://github.com/covalenthq/rudder), [`ipfs-pinner`](https://github.com/covalenthq/ipfs-pinner) and [`evm-server`](https://github.com/covalenthq/erigon) that coordinate and execute a transformation pipeline per Block Specimen.

Here `rudder` serves as the primary orchestrator and supervisor for all transformation pipeline processes that locates a source CQT Network data object to apply a tracing/execution/transformational rule to and outputs a new object generated from using such a rule.

Running these nodes are not as disk I/O (or cpu/memory) intense as running [`bsp-geth`](https://github.com/covalenthq/bsp-geth) and [`bsp-agent`](https://github.com/covalenthq/bsp-agent) on local machines, however they do require sufficient bandwidth for access to distributed store resources and sending transaction proofs using ethereum clients - connecting to our EVM public blockchain partner - [moonbeam](https://moonbeam.network/). We shall setup all of these step-by-step in this guide in two main ways:

- [Run with Docker Compose](#run-with-docker-compose) (Recommended method)

- [Build & Run from Source](#build-from-source) (Optional method)

### <span id="rudder_raison">Raison d'être</span>

![Phase2](./docs/phase-2.png)

As it stands, the Block Specimen captures a state snapshot. That is, all of the state read and transaction information. However, it doesn't capture the side effects of executing the block, the information you would get from a trace, transaction re-execution artifacts like `receipts`, what contracts were interacted with during a transaction, etc.

In theory, the Block Specimen could contain this information. However, the Block Specimen only includes the minimum information required to re-execute a block and all its transactions, making the network and decentralized storage more efficient. Extracting and storing block specimens allows us to move away from relying on blockchain nodes (executing blocks sequentially) to re-execute the block and draw detailed insights from underlying captured data. This process can be made concurrent, as block specimens can be executed independently as currently done with the [erigon/covalent t8n tool](https://github.com/covalenthq/erigon/tree/covalent/cmd/evm/internal/t8ntool), and does not need any state constructed from previous block specimens.

At a very high level, the Refiner locates a source to apply a transformational rule to and outputs an object generated from using such a rule. The source and output are available through a  decentralized storage service such as a wrapped IPFS node. A transformation-proof transaction is emitted, confirming that it has done this work along with the output content ids (ipfs) access URL. To define what these three components are:

- **Source**: The Block Specimen that serves as an input to the Refiner. Proof transactions made earlier to a smart contract with the respective cids are where the source is checked.

- **Rule**: A transformation plugin (or server) that can act on the Block Specimen (source). These can be compared to blueprints that have been shown to produce the data objects needed. Furthermore, anyone can create these rules to get a desired data object. Rule (or server) versions thus need to exist, tied to the decoded block specimen versions they are applied on.

- **Target**: The output generated from running the rule over the object that came from the source that is the block result.

## <span id="rudder_arch">Architecture</span>

![Rudder Pipeline](./docs/components.png)

The happy path for `rudder` application in the CQT Network is made up of actor processes spawned through many [Gen Servers](https://elixir-lang.org/getting-started/mix-otp/genserver.html) processes that are loosely coupled, here some maintain state, and some don't. The children processes can be called upon to fulfill responsibilities at different sections in the refinement/transformation process pipeline - under one umbrella [Dynamic Supervisor](https://elixir-lang.org/getting-started/mix-otp/dynamic-supervisor.html), that can bring them back up in case of a failure to continue a given pipeline operation. Read more about the components and their operations in the [FULL ARCHITECTURE document](./docs/ARCH.md).

## <span id="rudder _resources">Resources</span>

Production of Block Results forms the core of the cQT network’s functional data objects specs. These result objects are created using six main pieces of open-source software published by Covalent for the CQT Network’s decentralized blockchain data ETL stack.

![Resources](./docs/arch-white.png)

1. [Block Specimen Producer (Produce)](https://github.com/covalenthq/bsp-geth) - Operator run & deployed.
Open source granular bulk blockchain data production and export of block specimens.

1. [BSP Agent (Extract & Prove)](https://github.com/covalenthq/bsp-agent) - Operator run & deployed.
Open source packaging, encoding, proving (and storing specification) of block specimens.

1. [BSP Staking (Consensus)](https://github.com/covalenthq/bsp-staking) - Covalent foundation operated & pre-deployed.
Open source CQT staking and proof aggregating smart contracts deployed on moonbeam used for consensus and rewards distribution for cQT network operators.

1. [IPFS Pinner (Store)](https://github.com/covalenthq/ipfs-pinner) - Operator run & deployed.
Open source decentralized storage layer for cQT network block specimen and transformations (results).

1. [BSP Finalizer (Reward)](https://github.com/covalenthq/bsp-finalizer) - Covalent foundation operated & pre-deployed.
Open source (anyone can call the rewards function on BSP Staking contracts) rewards distributer for cQT network operators.

1. [T8n Server (Transform)](https://github.com/covalenthq/erigon) - Operator run & deployed.
Open source Ethereum virtual machine binary (stateless transition tool - t8n) plugin/http server for the rudder.

1. [Rudder (Refine & Prove)]( https://github.com/covalenthq/rudder) - Operator run & deployed.
Open Source specialized transformation process and framework for block specimens to block results (Open sourced in Q2 2023).

### <span id="rudder _resources_add">Additional Resources</span>

- Reference to understand the functions of the various components can be found in the official [CQT Network Whitepaper](https://www.covalenthq.com/docs/cqt-network/covalent-network-whitepaper/).

- Reference to understand the block specimen producer and its role in the CQT Network can be found in the official [Block Specimen Whitepaper](https://www.covalenthq.com/static/documents/Block%20Specimen%20Whitepaper%20V1.2.pdf).

- Reference to understand the Refiner's purpose, mission and its role in the CQT Network can be found in the official [Refiner Whitepaper](http://covalenthq.com/docs/cqt-network/refiner-whitepaper/)

- Operator reference for instructions to run BSP Geth with the BSP Agent can be found in [CQT Network: Block Specimen Producer Onboarding Process](https://www.covalenthq.com/docs/cqt-network/operator-onboarding-bsp/).

- Operator reference for instructions to run Rudder/Refiner be found in [CQT Network - Refiner Onboarding Process](https://www.covalenthq.com/docs/cqt-network/operator-onboarding-refiner/).

- View [The Refiner: A Web3 Solution for Accessing Granular Blockchain Data for Developers](https://www.youtube.com/watch?v=o7yTUY8s_Yk&pp=ygUQcmVmaW5lciBjb3ZhbGVudA%3D%3D)

- Setting up monitoring and alerting with [Grafana and Prometheus for Refiner](https://github.com/covalenthq/rudder/blob/main/docs/METRICS.md)

- Refiner [contributions and bug bounty guidelines](https://github.com/covalenthq/rudder/blob/main/docs/CONTRIBUTING.md)

- Detailed [Refiner Architecture](https://github.com/covalenthq/rudder/blob/main/docs/ARCH.md)

- Refiner [Incentivized Testnet Validator-Operator Onboarding](https://www.youtube.com/watch?v=PHx4NT1_1E0)

## <span id="rudder _requirements">Requirements</span>

**Minimum**

- 2 vCPUs (cores)
- 3GB RAM
- 200GB HDD free storage (mostly storing artifacts on local ipfs; can be pruned periodically)
- 8 MBit/sec download Internet service

**Recommended**

- 4 vCPUs
- 8 GB+ RAM
- SSD with >= 500GB storage space
- 25+ MBit/sec download Internet service

**Software Requirements (docker setup)**

- 64-bit Linux, Mac OS 13+
- SSL certificates
- docker, docker-compose, direnv

## <span id="rudder_docker">Run With Docker Compose</span>

Install Docker

Follow the instructions for your platform/architecture: https://docs.docker.com/engine/install.

README instructions will be based on Ubuntu 22.04 LTS x86_64/amd64: https://docs.docker.com/engine/install/ubuntu/.

### <span id="rudder_docker_env">Environment</span>

Install direnv

```bash
sudo apt update
sudo apt get direnv

# bash users - add the following line to your ~/.bashrc
eval "$(direnv hook bash)"
source ~/.bashrc

# zsh users - add the following line to your ~/.zshrc
eval "$(direnv hook zsh)"
source ~/.zshrc
```

Create `envrc.local` file and add the following env vars.

**Note**: When passing the private key into the env vars as above please remove the `0x` prefix so the private key env var has exactly 64 characters.
**Note**: You can get the value for `W3_AGENT_KEY` by asking on discord. It has to be issued to you from Covalent.

```bash
export BLOCK_RESULT_OPERATOR_PRIVATE_KEY="BRP-OPERATOR-PK-WITHOUT-0x-PREFIX"
export NODE_ETHEREUM_MAINNET="<<ASK-ON-DISCORD>>"
export IPFS_PINNER_URL="http://ipfs-pinner:3001"
export EVM_SERVER_URL="http://evm-server:3002"
export W3_AGENT_KEY="<<W3_AGENT_KEY>>"
```

Load the env vars.

```bash
direnv allow .
```

That will lead to the corresponding logs:

```bash
direnv: loading ~/rudder/.envrc
direnv: loading ~/rudder/.envrc.local
direnv: export +BLOCK_RESULT_OPERATOR_PRIVATE_KEY +ERIGON_NODE +EVM_SERVER_URL +IPFS_PINNER_URL +NODE_ETHEREUM_MAINNET +W3_AGENT_KEY
```

This shows that the shell is loaded correctly. You can check if they're what you expect.

```bash
echo $IPFS_PINNER_URL
http://ipfs-pinner:3001
```

Copy over the delegation proof file to ~/.ipfs repo. You should have gotten this from Covalent in addition to the `W3_AGENT_KEY` value.
```bash
mv path_to_delegation_file ~/.ipfs/proof.out
```

### <span id="rudder_docker_pull">Pull</span>

Run all services including `rudder` with [docker compose](https://docs.docker.com/compose/) with the following.

**Note**: the `env` file is not necessary if env vars are already loaded.

For moonbase.

```bash
docker compose --env-file ".env" -f "docker-compose-mbase.yml" up --remove-orphans
```

For moonbeam.

```bash
docker compose --env-file ".env" -f "docker-compose-mbeam.yml" up --remove-orphans
```

**NOTE**: On a system where an `ipfs-pinner` instance is already running, check the instruction in the [Appendix](#appendix) to run `rudder` docker alongside.

Running this will pull all the images and services that are ready to run.

This will lead to the corresponding logs:

```elixir
Started rudder compose.
  rudder Pulling
  ipfs-pinner Pulling
  evm-server Pulling
  4f4fb700ef54 Downloading [==================================================>]      32B/32B
  4f4fb700ef54 Verifying Checksum
  4f4fb700ef54 Download complete
  ipfs-pinner Pulled
  0b5445b067f6 Extracting [=>                                                 ]  393.2kB/11.45MB
  0b5445b067f6 Extracting [==========>                                        ]  2.359MB/11.45MB
  1fd45119e007 Downloading [==============>                                    ]  4.317MB/14.94MB
  evm-server Pulled
  1fd45119e007 Extracting [>                                                  ]  163.8kB/14.94MB
  1fd45119e007 Extracting [=>                                                 ]  491.5kB/14.94MB
  1fd45119e007 Extracting [==============>                                    ]   4.26MB/14.94MB
  1fd45119e007 Extracting [=========================>                         ]  7.537MB/14.94MB
  1fd45119e007 Extracting [====================================>              ]  10.81MB/14.94MB
  1fd45119e007 Extracting [================================================>  ]  14.42MB/14.94MB
  1fd45119e007 Extracting [==================================================>]  14.94MB/14.94MB
  1fd45119e007 Pull complete
  rudder Pulled
  Container evm-server  Recreate
  Container ipfs-pinner  Created
  Container evm-server  Recreated
  Container rudder  Recreated
 Attaching to evm-server, ipfs-pinner, rudder
```

Following this step a `rudder` release is auto compiled within the docker container and executed.

**Note**: The below example is for the `dev` env (`_build/dev/rel/rudder/bin/rudder`) binary referred to as moonbase.

For production the path to the binary would be to the `prod` env (`_build/prod/rel/rudder/bin/rudder`). This distinction is important since in elixir the static env vars (such as proof-chain contract address) are packaged with dynamic env vars (such as rpc to moonbeam/moonbase) along with the application binary.

Hence there is a single binary per "Environment". To understand more about this take a look at the [hex docs](https://hexdocs.pm/elixir/main/Config.html).

```elixir
 ipfs-pinner  | generating 2048-bit RSA keypair...done
 ipfs-pinner  | peer identity: QmeP85RqKmrTwbW6PTQoX3NGwkgLX8DhGa1mkdy67sHZMZ
 evm-server   | [INFO] [04-19|16:53:31.113] Listening                                port=3002
 ipfs-pinner  |
 ipfs-pinner  | Computing default go-libp2p Resource Manager limits based on:
 ipfs-pinner  |     - 'Swarm.ResourceMgr.MaxMemory': "4.2 GB"
 ipfs-pinner  |     - 'Swarm.ResourceMgr.MaxFileDescriptors': 524288
 ipfs-pinner  |
 ipfs-pinner  | Applying any user-supplied overrides on top.
 ipfs-pinner  | Run 'ipfs swarm limit all' to see the resulting limits.
 ipfs-pinner  |
 ipfs-pinner  | 2023/04/19 16:53:31 failed to sufficiently increase receive buffer size (was: 208 kiB, wanted: 2048 kiB, got: 416 kiB). See https://github.com/lucas-clemente/quic-go/wiki/UDP-Receive-Buffer-Size for details.
 rudder       | moonbase-node: https://moonbeam-alphanet.web3.covalenthq.com/alphanet/direct-rpc
 rudder       | brp-operator: ecf0b636233c6580f60f50ee1d809336c3a76640dbd77f7cdd054a82c6fc0a31
 rudder       | evm-server: http://evm-server:3002
 rudder       | ipfs-node: http://ipfs-pinner:3001
 ipfs-pinner  | 2023/04/19 16:53:31 Listening...
 rudder       | ==> nimble_options
 rudder       | Compiling 3 files (.ex)
 rudder       | Generated nimble_options app
 rudder       | ===> Analyzing applications...
 rudder       | ===> Compiling parse_trans
 rudder       | ==> logger_file_backend
 rudder       | Compiling 1 file (.ex)
 rudder       | Generated rudder app
 rudder       | * assembling rudder-0.2.2 on MIX_ENV=dev
 rudder       | * skipping runtime configuration (config/runtime.exs not found)
 rudder       | * skipping elixir.bat for windows (bin/elixir.bat not found in the Elixir installation)
 rudder       | * skipping iex.bat for windows (bin/iex.bat not found in the Elixir installation)
 rudder       |
 rudder       | Release created at _build/dev/rel/rudder
 rudder       |
 rudder       |     # To start your system
 rudder       |     _build/dev/rel/rudder/bin/rudder start
 rudder       |
 rudder       | Once the release is running:
 rudder       |
 rudder       |     # To connect to it remotely
 rudder       |     _build/dev/rel/rudder/bin/rudder remote
 rudder       |
 rudder       |     # To stop it gracefully (you may also send SIGINT/SIGTERM)
 rudder       |     _build/dev/rel/rudder/bin/rudder stop
 rudder       |
 rudder       | To list all commands:
 rudder       |
 rudder       |     _build/dev/rel/rudder/bin/rudder
 rudder       |
 rudder       | https://hexdocs.pm/telemetry/telemetry.html#attach/4
```

### <span id="rudder_docker_run">Docker Run</span>

Once the binary is compiled. Rudder can start to process block specimens into block results by starting the event listener.

```elixir
 rudder       | [info] starting event listener
 rudder       | [info] getting ids with status=discover
 rudder       | [info] found 1 bsps to process
 ipfs-pinner  | 2023/04/19 16:57:32 unixfsApi.Get: getting the cid: bafybeifkn67rc4lzoabvaglsifjitkhrnshhpwavutdhzeohzkxih25jpi
 ipfs-pinner  | 2023/04/19 16:57:32 trying out https://w3s.link/ipfs/bafybeifkn67rc4lzoabvaglsifjitkhrnshhpwavutdhzeohzkxih25jpi
 rudder       | [info] Counter for ipfs_metrics - [fetch: 1]
 rudder       | [info] LastValue for ipfs_metrics - [fetch_last_exec_time: 0.0015149999999999999]
 rudder       | [info] Sum for ipfs_metrics - [fetch_total_exec_time: 0.0015149999999999999]
 rudder       | [info] Summary for ipfs_metrics  - {0.0015149999999999999, 0.0015149999999999999}
 rudder       | [debug] reading schema `block-ethereum` from the file /app/priv/schemas/block-ethereum.avsc
 rudder       | [info] Counter for bsp_metrics - [decode: 1]
 rudder       | [info] LastValue for bsp_metrics - [decode_last_exec_time: 0.0]
 rudder       | [info] Sum for bsp_metrics - [decode_total_exec_time: 0.0]
 rudder       | [info] Summary for bsp_metrics  - {0.0, 0.0}
 rudder       | [info] submitting 17081820 to evm http server...
 evm-server   | [INFO] [04-19|16:57:33.824] input file at                            loc=/tmp/23851799
 evm-server   | [INFO] [04-19|16:57:33.828] output file at:                          loc=/tmp/1143694015
 evm-server   | [INFO] [04-19|16:57:34.153] Wrote file                               file=/tmp/1143694015
 rudder       | [info] writing block result into "/tmp/briefly-1681/briefly-576460651588718236-AE8SrEl8GLI9jKhCKPk"
 rudder       | [info] Counter for bsp_metrics - [execute: 1]
 rudder       | [info] LastValue for bsp_metrics - [execute_last_exec_time: 3.9e-4]
 rudder       | [info] Sum for bsp_metrics - [execute_total_exec_time: 3.9e-4]
 rudder       | [info] Summary for bsp_metrics  - {3.9e-4, 3.9e-4}
 ipfs-pinner  | 2023/04/19 16:57:34 generated dag has root cid: bafybeifd6gz6wofk3bwb5uai7zdmmr23q3nz3zt7edfujgj4kjg2es7eee
 ipfs-pinner  | 2023/04/19 16:57:34 car file location: /tmp/1543170755.car
 ipfs-pinner  | 2023/04/19 16:57:35 uploaded file has root cid: bafybeifd6gz6wofk3bwb5uai7zdmmr23q3nz3zt7edfujgj4kjg2es7eee
 rudder       | [info] Counter for ipfs_metrics - [pin: 1]
 rudder       | [info] LastValue for ipfs_metrics - [pin_last_exec_time: 0.001132]
 rudder       | [info] Sum for ipfs_metrics - [pin_total_exec_time: 0.001132]
 rudder       | [info] Summary for ipfs_metrics  - {0.001132, 0.001132}
 rudder       | [info] 17081820:556753def2ff689c6312241a1ca182d58467319b7c2dca250ca50ed6acb31a5d has been successfully uploaded at ipfs://bafybeifd6gz6wofk3bwb5uai7zdmmr23q3nz3zt7edfujgj4kjg2es7eee
 rudder       | [info] 17081820:556753def2ff689c6312241a1ca182d58467319b7c2dca250ca50ed6acb31a5d proof submitting
 rudder       | [info] Counter for brp_metrics - [proof: 1]
 rudder       | [info] LastValue for brp_metrics - [proof_last_exec_time: 3.03e-4]
 rudder       | [info] Sum for brp_metrics - [proof_total_exec_time: 3.03e-4]
 rudder       | [info] Summary for brp_metrics  - {3.03e-4, 3.03e-4}
 rudder       | [info] 17081820 txid is 0x01557912a0f7e083cbf6d34a2af21d99d129af386b95edc16162202862c60f8d
 rudder       | [info] Counter for brp_metrics - [upload_success: 1]
 rudder       | [info] LastValue for brp_metrics - [upload_success_last_exec_time: 0.0014579999999999999]
 rudder       | [info] Sum for brp_metrics - [upload_success_total_exec_time: 0.0014579999999999999]
 rudder       | [info] Summary for brp_metrics  - {0.0014579999999999999, 0.0014579999999999999}
 rudder       | [info] Counter for rudder_metrics - [pipeline_success: 1]
 rudder       | [info] LastValue for rudder_metrics - [pipeline_success_last_exec_time: 0.0035489999999999996]
 rudder       | [info] Sum for rudder_metrics - [pipeline_success_total_exec_time: 0.0035489999999999996]
 rudder       | [info] Summary for rudder_metrics  - {0.0035489999999999996, 0.0035489999999999996}
 rudder       | [info] curr_block: 4180658 and latest_block_num:4180657
```
### <span id="rudder_monitor">Monitor</span>

`rudder` already captures the most relevant performance metrics and execution times for various processes in the pipeline and exports all of it using Prometheus.

See the full document on how to setup Prometheus and Grafana for [rudder metrics collection, monitoring, reporting and alerting](./docs/METRICS.md)

## <span id="rudder_source">Build From Source</span>

Installation Time: 35-40 mins depending on your machine and network.

Install `git`, `go`, `asdf`, `erlang`, `elixir`, `direnv`, `go-ipfs`.

- Git is the source code version control manager across all our repositories.
- Go is the programming language used to develop on `go-ethereum`, `bsp-agent`, `erigon` (EVM plugin), all of which are entirely written in go.
- Asdf is a CLI tool that can manage multiple language runtime versions per-project.
- Erlang is a programming language used to build massively scalable soft real-time systems with requirements of high availability.
- Elixir is a programming language that runs on the Erlang VM, known for creating low-latency, distributed, high concurrency fault-tolerant systems.
- IPFS as the InterPlanetary File System (IPFS) is a protocol, hypermedia and file sharing peer-to-peer network for storing and sharing data in a distributed file system.
- Direnv is used for secret management and control since all the necessary sensitive parameters to the agent cannot be passed into a command line flag. Direnv allows for safe and easy management of secrets like Ethereum private keys for the operator accounts on the CQT network and redis instance access passwords etc. As these applications are exposed to the internet on http ports, it’s essential not to have the information be logged anywhere. To enable “direnv” on your machine, add these to your ~./bash_profile or ~./zshrc depending on which you use as your default shell after installing it using brew.

### <span id="rudder_source_linux">Linux x86_64 (Ubuntu 22.04 LTS) Install dependencies</span>

Install dependencies for rudder.

```bash
sudo apt update
sudo apt install build-essential coreutils libssl-dev automake autoconf libncurses5-dev curl git wget direnv unzip

git clone https://github.com/asdf-vm/asdf.git ~/.asdf --branch v0.11.2
echo ". $HOME/.asdf/asdf.sh" >> ~/.bashrc
echo ". $HOME/.asdf/completions/asdf.bash" >> ~/.bashrc
source ~/.bashrc
```

Install required `asdf` version manager plugins for erlang, elixir and golang.

```bash
asdf plugin add erlang https://github.com/asdf-vm/asdf-erlang.git
asdf plugin add elixir https://github.com/asdf-vm/asdf-elixir.git
asdf plugin add golang https://github.com/kennyp/asdf-golang.git
```

Add to your shell for `asdf` (check for different shells - https://asdf-vm.com/guide/getting-started.html).

```bash
`echo -e "\n. \"$(brew --prefix asdf)/etc/bash_completion.d/asdf.bash\"" >> ~/.bash_profile`
```

Install Erlang, Elixir and Golang using the plugins.

```bash
asdf install erlang 25.0.3
asdf install elixir 1.14.3
asdf install golang 1.18.4
```

Set the versions.

```bash
asdf global erlang 25.0.3
asdf global elixir 1.14.3
asdf global golang 1.18.4
```

This will create a .tool-versions file in your home directory. ASDF will use these versions whenever a project doesn't specify versions of its own.

Enable direnv for shell bash/powershell(zsh).

```bash
# bash users - add the following line to your ~/.bashrc
eval "$(direnv hook bash)"

# zsh users - add the following line to your ~/.zshrc
eval "$(direnv hook zsh)"
```

After adding this line do not forget to source your bash/powershell config with the following, by running it in your terminal.

```bash
source ~/.zshrc
source ~/.bashrc
```

Install `go-ipfs/kubo v0.13.0` and initialize `go-ipfs`.

```bash
wget https://dist.ipfs.tech/go-ipfs/v0.13.0/go-ipfs_v0.13.0_linux-amd64.tar.gz
tar -xzvf go-ipfs_v0.13.0_darwin-arm64.tar.gz
cd go-ipfs
bash install.sh
ipfs init
```

**Note**: To avoid permissions and netscan issues execute the following against ipfs binary home directory application

```bash
sudo chmod -R 700 ~/.ipfs
ipfs config profile apply server
```

### <span id="rudder_source_env">Env Vars</span>

Refer to the above existing environment var setup for [rudder docker compose](#environment).

**Note**: When passing the private key into the env vars as above, please remove the 0x prefix so the private key env var has exactly 64 characters.

### <span id="rudder_source_run">Source Run</span>

The EVM-Server is a stateless EVM block execution tool. It's stateless because in Ethereum nodes like geth, it doesn't need to maintain database of blocks to do a block execution or re-execution. The `evm-server` service transforms Block Specimens to Block Results entirely on the input of underlying capture of Block Specimen data.

Clone [covalenthq/erigon](https://github.com/covalenthq/erigon) that contains the fork for this particular stateless execution function, checkout the `covalent` branch, build the `evm-server` binary and run it.

```bash
git checkout covalent
make evm

Updating git submodules
Building evm
go: downloading github.com/ledgerwatch/erigon-lib v0.0.0-20230328191829-416af23d9dcd...

```

Run the generated binary

```bash
./build/bin/evm t8n --server.mode --server.port 3002

INFO[04-17|11:03:07.516] Listening                                port=3002
```

The IPFS-Pinner is an interface to the storage layer of the CQT network using a decentralized storage network underneath. Primarily it's a custom [IPFS (Inter Planetary File System)](https://ipfs.tech/) node with pinning service components for [Web3.storage](https://web3.storage/) and [Pinata](https://www.pinata.cloud/); content archive manipulation etc. Additionally there's support for fetching using `dweb.link`. It is meant for uploading/fetching artifacts (like Block Specimens and uploading Block Results or any other processed/transformed data asset) of the Covalent Decentralized Network.

Clone [covalenthq/ipfs-pinner](https://github.com/covalenthq/ipfs-pinner) and build the pinner server binary

```bash
git clone https://github.com/covalenthq/ipfs-pinner.git --depth 1
cd ipfs-pinner
make server-dbg
```

You should get the "w3 agent key" and "delegation proof file" from Covalent. After that, start the `ipfs-pinner` server.

```bash
./build/bin/server -w3-agent-key $W3_AGENT_KEY -w3-delegation-file $W3_DELEGATION_FILE

generating 2048-bit RSA keypair...done
peer identity: QmZQSGUEVKQuCmChKqTBGdavEKGheCQgKgo2rQpPiQp7F8

Computing default go-libp2p Resource Manager limits based on:
    - 'Swarm.ResourceMgr.MaxMemory': "17 GB"
    - 'Swarm.ResourceMgr.MaxFileDescriptors': 61440

Applying any user-supplied overrides on top.
Run 'ipfs swarm limit all' to see the resulting limits.

2023/04/20 12:47:49 Listening...
```

Clone the `rudder` repo

```bash
git clone https://github.com/covalenthq/rudder.git
cd rudder
git checkout main
```

Get your `BLOCK_RESULT_OPERATOR_PRIVATE_KEY` that has `DEV` tokens for Moonbase Alpha and is already whitelisted as Block Result Producer operator. Set the following environment variables for the local rudder by creating an `.envrc.local` file

```bash
touch .envrc.local
```

Copy paste the environment variables into this file

```bash
export BLOCK_RESULT_OPERATOR_PRIVATE_KEY="BRP-OPERATOR-PK-WITHOUT-0x-PREFIX"
export NODE_ETHEREUM_MAINNET="<<ASK-ON-DISCORD>>"
export IPFS_PINNER_URL="http://127.0.0.1:3001"
export EVM_SERVER_URL="http://127.0.0.1:3002"
```

Call to load `.envrc.local + .envrc` files with the command below and observe the following output, make sure the environment variables are loaded into the shell.

```bash
direnv allow .

direnv: loading ~/Covalent/rudder/.envrc
direnv: loading ~/Covalent/rudder/.envrc.local
direnv: export +BLOCK_RESULT_OPERATOR_PRIVATE_KEY +ERIGON_NODE +IPFS_PINNER_URL +NODE_ETHEREUM_MAINNET
```

Once the env vars are passed into the `.envrc.local` file and loaded in the shell with `direnv allow .`, build the `rudder` application for the `prod` env i.e moonbeam mainnet or `dev` env for moonbase alpha as discussed before.

Get all the required dependencies and build the `rudder` app for the `dev` environment (this points to Moonbase Alpha contracts). **Note**: Windows is currently not supported.

```bash
mix local.hex --force && mix local.rebar --force && mix deps.get
```

For moonbeam mainnet.

```bash
MIX_ENV=prod mix release
```

For moonbase alpha.

```bash
MIX_ENV=dev mix release
.
..
....
evm-server: http://127.0.0.1:3002
ipfs-node: http://127.0.0.1:3001
* assembling rudder-0.2.12 on MIX_ENV=dev
* skipping runtime configuration (config/runtime.exs not found)
* skipping elixir.bat for windows (bin/elixir.bat not found in the Elixir installation)
* skipping iex.bat for windows (bin/iex.bat not found in the Elixir installation)
Release created at _build/dev/rel/rudder
    # To start your system
    _build/dev/rel/rudder/bin/rudder start
Once the release is running:
    # To connect to it remotely
    _build/dev/rel/rudder/bin/rudder remote
    # To stop it gracefully (you may also send SIGINT/SIGTERM)
    _build/dev/rel/rudder/bin/rudder stop
To list all commands:
   _build/dev/rel/rudder/bin/rudder
```

Start the `rudder` application and execute the proof-chain block specimen listener call which should run the Refiner pipeline pulling Block Specimens from IPFS using the cids read from recent proof-chain finalized transactions, decoding them, and uploading and proofing Block Results while keeping a track of failed ones and continuing (soft real-time) in case of failure. The erlang concurrent fault tolerance allows each pipeline to be an independent worker that can fail (for any given Block Specimen) without crashing the entire pipeline application. Multiple pipeline worker children threads continue their work in the synchronous queue of Block Specimen AVRO binary files running the stateless EVM binary (`evm-server`) re-execution tool.

For moonbeam.

```elixir
MIX_ENV=prod mix run --no-halt --eval 'Rudder.ProofChain.BlockSpecimenEventListener.start()';
```

For moonbase.

```bash
MIX_ENV=dev mix run --no-halt --eval 'Rudder.ProofChain.BlockSpecimenEventListener.start()';
..
...
rudder       | [info] found 1 bsps to process
ipfs-pinner  | 2023/06/29 20:28:30 unixfsApi.Get: getting the cid: bafybeiaxl44nbafdmydaojz7krve6lcggvtysk6r3jaotrdhib3wpdb3di
ipfs-pinner  | 2023/06/29 20:28:30 trying out https://w3s.link/ipfs/bafybeiaxl44nbafdmydaojz7krve6lcggvtysk6r3jaotrdhib3wpdb3di
ipfs-pinner  | 2023/06/29 20:28:31 got the content!
rudder       | [info] Counter for ipfs_metrics - [fetch: 1]
rudder       | [info] LastValue for ipfs_metrics - [fetch_last_exec_time: 0.001604]
rudder       | [info] Sum for ipfs_metrics - [fetch_total_exec_time: 0.001604]
rudder       | [info] Summary for ipfs_metrics  - {0.001604, 0.001604}
rudder       | [debug] reading schema `block-ethereum` from the file /app/priv/schemas/block-ethereum.avsc
rudder       | [info] Counter for bsp_metrics - [decode: 1]
rudder       | [info] LastValue for bsp_metrics - [decode_last_exec_time: 0.0]
rudder       | [info] Sum for bsp_metrics - [decode_total_exec_time: 0.0]
rudder       | [info] Summary for bsp_metrics  - {0.0, 0.0}
rudder       | [info] submitting 17586995 to evm http server...
evm-server   | [INFO] [06-29|20:28:31.859] input file at                            loc=/tmp/3082854681
evm-server   | [INFO] [06-29|20:28:31.862] output file at:                          loc=/tmp/1454174090
evm-server   | [INFO] [06-29|20:28:32.112] Wrote file                               file=/tmp/1454174090
rudder       | [info] writing block result into "/tmp/briefly-1688/briefly-576460747542186916-YRw0mRjfExGMk4M672"
rudder       | [info] Counter for bsp_metrics - [execute: 1]
rudder       | [info] LastValue for bsp_metrics - [execute_last_exec_time: 3.14e-4]
rudder       | [info] Sum for bsp_metrics - [execute_total_exec_time: 3.14e-4]
rudder       | [info] Summary for bsp_metrics  - {3.14e-4, 3.14e-4}
ipfs-pinner  | 2023/06/29 20:28:32 generated dag has root cid: bafybeic6ernzbb6x4qslwfgklveisyz4vkuqhaafqzwlvto6c2njonxi3e
ipfs-pinner  | 2023/06/29 20:28:32 car file location: /tmp/249116437.car
[119B blob data]
ipfs-pinner  | 2023/06/29 20:28:34 Received /health request: source= 127.0.0.1:34980 status= OK
ipfs-pinner  | 2023/06/29 20:28:34 uploaded file has root cid: bafybeic6ernzbb6x4qslwfgklveisyz4vkuqhaafqzwlvto6c2njonxi3e
rudder       | [info] Counter for ipfs_metrics - [pin: 1]
rudder       | [info] LastValue for ipfs_metrics - [pin_last_exec_time: 0.002728]
rudder       | [info] Sum for ipfs_metrics - [pin_total_exec_time: 0.002728]
rudder       | [info] Summary for ipfs_metrics  - {0.002728, 0.002728}
rudder       | [info] 17586995:48f1e992d1ac800baed282e12ef4f2200820061b5b8f01ca0a9ed9a7d6b5ddb3 has been successfully uploaded at ipfs://bafybeic6ernzbb6x4qslwfgklveisyz4vkuqhaafqzwlvto6c2njonxi3e
rudder       | [info] 17586995:48f1e992d1ac800baed282e12ef4f2200820061b5b8f01ca0a9ed9a7d6b5ddb3 proof submitting
rudder       | [info] Counter for brp_metrics - [proof: 1]
rudder       | [info] LastValue for brp_metrics - [proof_last_exec_time: 3.6399999999999996e-4]
rudder       | [info] Sum for brp_metrics - [proof_total_exec_time: 3.6399999999999996e-4]
rudder       | [info] Summary for brp_metrics  - {3.6399999999999996e-4, 3.6399999999999996e-4}
rudder       | [info] 17586995 txid is 0xd8a8ea410240bb0324433bc26fdc79d496ad0c8bfd18b60314a05e3a0de4fb06
rudder       | [info] Counter for brp_metrics - [upload_success: 1]
rudder       | [info] LastValue for brp_metrics - [upload_success_last_exec_time: 0.0031149999999999997]
rudder       | [info] Sum for brp_metrics - [upload_success_total_exec_time: 0.0031149999999999997]
rudder       | [info] Summary for brp_metrics  - {0.0031149999999999997, 0.0031149999999999997}
rudder       | [info] Counter for rudder_metrics - [pipeline_success: 1]
rudder       | [info] LastValue for rudder_metrics - [pipeline_success_last_exec_time: 0.0052]
rudder       | [info] Sum for rudder_metrics - [pipeline_success_total_exec_time: 0.0052]
rudder       | [info] Summary for rudder_metrics  - {0.0052, 0.0052}
```

Check logs for any errors in the pipeline process and note the performance metrics in line with execution. Checkout the documentation on what is being measured and why [here](https://github.com/covalenthq/rudder/blob/main/docs/METRICS.md).

```bash
tail -f logs/log.log
..
...
rudder       | [info] Counter for rudder_metrics - [pipeline_success: 1]
rudder       | [info] LastValue for rudder_metrics - [pipeline_success_last_exec_time: 0.0052]
rudder       | [info] Sum for rudder_metrics - [pipeline_success_total_exec_time: 0.0052]
rudder       | [info] Summary for rudder_metrics  - {0.0052, 0.0052}
```

Alternatively - check proof-chain logs for correct block result proof submissions and transactions made by your block result producer.

[For moonbeam.](https://moonscan.io/address/0x4f2E285227D43D9eB52799D0A28299540452446E)

[For moonbase](https://moonbase.moonscan.io/address/0x19492a5019B30471aA8fa2c6D9d39c99b5Cda20C).

**Note**:For any issues associated with building and re-compiling execute the following commands, that cleans, downloads and re-compiles the dependencies for `rudder`.

```bash
rm -rf _build deps && mix clean && mix deps.get && mix deps.compile
```

If you got everything working so far. Congratulations! You're now a Refiner operator on the CQT Network. Set up Grafana monitoring and alerting from links in the [additional resources](#additional-resources) section.

## <span id="rudder_troubleshooting">Troubleshooting</span>

To avoid permission errors with ~/.ipfs folder execute the following in your home directory.

```bash
sudo chmod -R 770 ~/.ipfs
```

To avoid netscan issue execute the following against ipfs binary application.

```bash
sudo chmod -R 700 ~/.ipfs
ipfs config profile apply server
```

To avoid issues with `ipfs-pinner` v0.1.9, a small repo migration for the local `~/.ipfs` directory may be needed from - https://github.com/ipfs/fs-repo-migrations/blob/master/run.md.

For linux systems follow the below steps.

```bash
wget https://dist.ipfs.tech/fs-repo-migrations/v2.0.2/fs-repo-migrations_v2.0.2_linux-amd64.tar.gz
tar -xvf fs-repo-migrations_v2.0.2_linux-amd64.tar.gz
cd fs-repo-migrations
chmod +x ./fs-repo-migrations
./fs-repo-migrations
```

### <span id="rudder_contributions">Bugs Reporting Contributions</span>

Please follow the guide in docs [contribution guidelines](./docs/CONTRIBUTING.md) for bug reporting and contributions.

## <span id="rudder_scripts">Scripts</span>

In order to run the Refiner docker compose services as a service unit. The example service unit file in [docs](./docs/rudder-compose.service) should suffice. After adding the env vars in their respective fields in the service unit file, enable the service and start it.

```bash
sudo systemctl enable rudder-compose.service
sudo systemctl start rudder-compose.service
```

**Note**:: To run docker compose as a non-root user for the above shown service unit, you need to create a docker group (if it doesn't exist) and add the user “blockchain” to the docker group.

```bash
sudo groupadd docker
sudo usermod -aG docker blockchain
sudo su - blockchain
docker run hello-world
```

### Appendix

#### Run With Existing IPFS-Pinner Service

On a system where an `ipfs-pinner` instance is already running, use this modified `.envrc.local` and `docker-compose-mbase.yml`

```bash
export BLOCK_RESULT_OPERATOR_PRIVATE_KEY="BRP-OPERATOR-PK-WITHOUT-0x-PREFIX"
export NODE_ETHEREUM_MAINNET="<<ASK-ON-DISCORD>>"
export IPFS_PINNER_URL="http://host.docker.internal:3001"
export EVM_SERVER_URL="http://evm-server:3002"
```

**Note**: When passing the private key into the env vars as above please remove the `0x` prefix so the private key env var has exactly 64 characters.

```bash
version: '3'
# runs the entire rudder pipeline with all supporting services (including rudder) in docker
# set .env such that all services in docker are talking to each other only; ipfs-pinnern is assumed
# to be hosted on the host machine. It's accessed through http://host.docker.internal:3001/ url from
# inside rudder docker container.
services:
  evm-server:
    image: "us-docker.pkg.dev/covalent-project/network/evm-server:stable"
    container_name: evm-server
    restart: always
    labels:
      "autoheal": "true"
    expose:
      - "3002:3002"
    networks:
      - cqt-net
    ports:
      - "3002:3002"

  rudder:
    image: "us-docker.pkg.dev/covalent-project/network/rudder:stable"
    container_name: rudder
    links:
      - "evm-server:evm-server"
    restart: always
    depends_on:
      evm-server:
        condition: service_healthy
    entrypoint: >
      /bin/bash -l -c "
        echo "moonbeam-node:" $NODE_ETHEREUM_MAINNET;
        echo "evm-server:" $EVM_SERVER_URL;
        echo "ipfs-pinner:" $IPFS_PINNER;
        cd /app;
        MIX_ENV=prod mix release --overwrite;
        MIX_ENV=prod mix run --no-halt --eval 'Rudder.ProofChain.BlockSpecimenEventListener.start()';"
    environment:
      - NODE_ETHEREUM_MAINNET=${NODE_ETHEREUM_MAINNET}
      - BLOCK_RESULT_OPERATOR_PRIVATE_KEY=${BLOCK_RESULT_OPERATOR_PRIVATE_KEY}
      - EVM_SERVER_URL=${EVM_SERVER_URL}
      - IPFS_PINNER_URL=${IPFS_PINNER_URL}
    networks:
      - cqt-net
    extra_hosts:
      - "host.docker.internal:host-gateway"
    ports:
      - "9568:9568"

  autoheal:
    image: willfarrell/autoheal
    container_name: autoheal
    volumes:
      - '/var/run/docker.sock:/var/run/docker.sock'
    environment:
      - AUTOHEAL_INTERVAL=10
      - CURL_TIMEOUT=30

networks:
  cqt-net:
```

and start the `rudder` and `evm-server` services:

```bash
$ docker compose -f "docker-compose-mbeam.yml" up --remove-orphans

[+] Running 3/3
 ⠿ Network rudder_cqt-net  Created                                   0.0s
 ⠿ Container evm-server     Started                                   0.7s
 ⠿ Container rudder         Started                                   1.5s
```
