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
docker pull gcr.io/covalent-project/rudder:latest
```

### <span id="rudder_docker_env">Environment</span>

Add the env vars to a .env file as below. Ask your node operator about these if you have questions. Check the `.env_example` for the list of required (and optional) environment variables.