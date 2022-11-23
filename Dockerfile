#===========
#(Elixir) Build Stage
#===========
FROM elixir:1.13.4-otp-25 as builder-elixir
COPY config ./config
COPY lib ./lib
COPY plugins ./plugins
COPY priv ./priv
COPY test ./test
COPY test-data ./test-data
COPY mix.exs ./mix.exs
COPY .gitmodules ./gitmodules
COPY .git ./git

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

# clone the eriogn plugin repo
RUN git clone -b covalent https://github.com/covalenthq/erigon

#===========
#(Go) Build Stage
#===========
FROM crazymax/goxx:1.19.2 as builder-go
# RUN apk update && apk add --no-cache git=2.36.3-r0 bash=5.1.16-r2 make=4.3-r0 gcc=11.2.1_git20220219-r2 musl-dev=1.2.3-r2 libc-dev=6.0.3-1
RUN mkdir -p /plugins/erigon/build/bin
WORKDIR /plugins
COPY --from=builder-elixir erigon ./erigon 
RUN cd erigon && make evm-prod


#================
#Deployment Stage
#================
FROM elixir:1.13.4-otp-25-alpine as deployer
# RUN mkdir -p /node/test /node/prod
RUN apk update && apk add --no-cache git=2.36.3-r0 bash=5.1.16-r2
RUN mkdir -p /node/_build /node/config /node/deps /node/lib /node/plugins /node/priv node/test /node/test-data /node/evm-out
WORKDIR /node
RUN mix local.hex --force

COPY --from=builder-elixir _build ./_build
COPY --from=builder-elixir config ./config
COPY --from=builder-elixir deps ./deps
COPY --from=builder-elixir lib ./lib
COPY --from=builder-elixir priv ./priv
COPY --from=builder-elixir mix.exs .
COPY --from=builder-elixir mix.lock .
# COPY --from=builder-elixir _build/prod/rel/rudder ./prod/
COPY --from=builder-elixir test/ ./test
COPY --from=builder-elixir test-data/ ./test-data
COPY --from=builder-go plugins/erigon/build/bin ./plugins
RUN cd plugins && chmod +x evm

CMD [ "mix", "test"]
# ENV 

# "echo", "$NODE_ETHEREUM_MAINNET", "echo" "$BLOCK_RESULT_OPERATOR_PRIVATE_KEY", "echo","$ERIGON_NODE"  