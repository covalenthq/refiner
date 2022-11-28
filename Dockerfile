#===========
#(Elixir) Build Stage
#===========
FROM elixir:1.13.4-otp-25 as builder-elixir
RUN mkdir -p /mix
WORKDIR /mix

COPY config ./config
COPY lib ./lib
COPY priv ./priv
COPY test ./test
COPY test-data ./test-data
COPY mix.exs .
# COPY plugins ./plugins

# Install rust tooling
RUN curl https://sh.rustup.rs -sSf | sh -s -- -y
# Add .cargo/bin to PATH
ENV PATH="/root/.cargo/bin:${PATH}"

# test release
RUN mix local.hex --force && \
    mix local.rebar --force && \
    mix deps.get && \
    MIX_ENV=test mix do compile

# dev release (copy release to next stage from _build) [Enable once tests work in docker]
# RUN mix release

# clone the erigon plugin repo
RUN git clone -b covalent https://github.com/covalenthq/erigon

#===========
#(Go) Build Stage
#===========
FROM crazymax/goxx:1.18.4 as builder-go
# RUN apk update && apk add --no-cache git=2.36.3-r0 bash=5.1.16-r2 make=4.3-r0 gcc=11.2.1_git20220219-r2 musl-dev=1.2.3-r2 libc-dev=6.0.3-1
RUN mkdir -p /plugins/erigon/build/bin
WORKDIR /plugins
COPY --from=builder-elixir /mix/erigon ./erigon
RUN cd erigon && make evm-prod


#================
#Deployment Stage
#================
FROM elixir:1.13.4-otp-25-alpine as deployer
# RUN mkdir -p /app/test /app/prod
RUN apk update && apk add --no-cache git=2.36.3-r0 bash=5.1.16-r2 curl=7.83.1-r4
RUN mkdir -p /app/_build /app/config /app/deps /app/lib /app/plugins /app/priv node/test /app/test-data /app/evm-out
WORKDIR /app
RUN mix local.hex --force

COPY --from=builder-elixir /mix/_build ./_build
COPY --from=builder-elixir /mix/config ./config
COPY --from=builder-elixir /mix/deps ./deps
COPY --from=builder-elixir /mix/lib ./lib
COPY --from=builder-elixir /mix/priv ./priv
COPY --from=builder-elixir /mix/mix.exs .
COPY --from=builder-elixir /mix/mix.lock .
# COPY --from=builder-elixir build/_build/prod/rel/rudder ./prod/
COPY --from=builder-elixir /mix/test/ ./test
COPY --from=builder-elixir /mix/test-data/ ./test-data
# COPY --from=builder-elixir mix/plugins/ ./plugins
COPY --from=builder-go /plugins/erigon/build/bin ./plugins

RUN cd plugins && chmod +x evm

CMD [ "mix", "test"]