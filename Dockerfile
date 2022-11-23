#===========
#Build Stage
#===========
FROM elixir:1.13.4-otp-25 as builder
COPY config ./config
COPY lib ./lib
COPY plugins ./plugins
COPY priv ./priv
COPY test ./test
COPY test-data ./test-data
COPY mix.exs ./mix.exs

# # Update default packages
# RUN apt-get update
# RUN apt-get install -y \
#     build-essential \
#     curl

# Install rust tooling
RUN curl https://sh.rustup.rs -sSf | sh -s -- -y
# Add .cargo/bin to PATH
ENV PATH="/root/.cargo/bin:${PATH}"

# test release
RUN rm -Rf _build && \
    mix local.hex --force && \
    mix local.rebar --force && \
    mix deps.get && \
    MIX_ENV=test mix do compile

# dev release (copy release to next stage from _build)
RUN mix release

#================
#Deployment Stage
#================
FROM elixir:1.13.4-otp-25-alpine as deployer
# RUN mkdir -p /node/test /node/prod 
RUN apk update && apk add --no-cache git=2.36.3-r0
RUN mkdir -p /node/_build /node/config /node/deps /node/lib /node/plugins /node/priv node/test /node/test-data /node/evm-out
WORKDIR /node
RUN mix local.hex --force

COPY --from=builder _build ./_build
COPY --from=builder config ./config
COPY --from=builder deps ./deps
COPY --from=builder lib ./lib
COPY --from=builder plugins ./plugins
COPY --from=builder priv ./priv
COPY --from=builder mix.exs .
COPY --from=builder mix.lock .
# COPY --from=builder _build/prod/rel/rudder ./prod/
COPY --from=builder test/ ./test
COPY --from=builder test-data/ ./test-data

CMD [ "mix", "test"]
# ENV 

# "echo", "$NODE_ETHEREUM_MAINNET", "echo" "$BLOCK_RESULT_OPERATOR_PRIVATE_KEY", "echo","$ERIGON_NODE"  