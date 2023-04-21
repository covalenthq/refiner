# Development

## Test

To start mock node, ProofChain, IPFS-Pinner and EVM server in Terminal 1 run:

```bash
docker compose --env-file '.env' -f 'docker-compose-mbase.yml' up --remove-orphans
```

Wait a minute then in Terminal 2 run:

```elixir
mix test
```

### <span id="rudder_docker_pull">Pull</span>

Pull only the latest containerized version of rudder using the following -

Make sure you're logged into gcr by running

```bash
gcloud auth print-access-token | docker login -u oauth2accesstoken --password-stdin https://gcr.io
```

Pull image

```docker
docker pull us-docker.pkg.dev/covalent-project/network/rudder
```

### <span id="rudder_docker_env">Environment</span>

Add the env vars to a .env file as below. Ask your node operator about these if you have questions. Check the `.env_example` for the list of required (and optional) environment variables.

**Note**: When passing the private key into the env vars as above please remove the `0x` prefix so the private key env var has exactly 64 characters.

```bash
export BLOCK_RESULT_OPERATOR_PRIVATE_KEY=block-result-operator-private-key-without-0x-prefix
export NODE_ETHEREUM_MAINNET="https://moonbeam-alphanet.web3.covalenthq.com/alphanet/direct-rpc"
export IPFS_PINNER_URL="http://ipfs-pinner:3000"
export EVM_SERVER_URL="http://evm-server:3002"
export WEB3_JWT="****"
```
