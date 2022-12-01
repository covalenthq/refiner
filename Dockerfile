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
COPY plugins ./plugins

# Install rust tooling
RUN curl https://sh.rustup.rs -sSf | sh -s -- -y
# Add .cargo/bin to PATH
ENV PATH="/root/.cargo/bin:${PATH}"

# clone the erigon plugin repo
RUN git clone -b covalent https://github.com/covalenthq/erigon

# test release
RUN mix local.hex --force && \
    mix local.rebar --force && \
    mix deps.get && \
    MIX_ENV=test mix do compile

# dev release (copy release to next stage from _build) [Enable once tests work in docker]
RUN mix release

RUN apt-get update && apt-get install -y build-essential && apt-get clean && rm -rf /var/lib/apt/lists/*
RUN curl -OL https://golang.org/dl/go1.19.linux-amd64.tar.gz
RUN tar -C /usr/local -xvf go1.19.linux-amd64.tar.gz


ENV PATH=$PATH:/usr/local/go/bin
RUN go version
RUN mkdir -p /mix/erigon/build/bin
RUN cd erigon && make evm-prod


#===========
#(Go) Build Stage (Skip building binary for now)
#===========
# FROM crazymax/goxx:1.18.4 as builder-go
# RUN apk update && apk add --no-cache git=2.36.3-r0 bash=5.1.16-r2 make=4.3-r0 gcc=11.2.1_git20220219-r2 musl-dev=1.2.3-r2 libc-dev=6.0.3-1
# RUN mkdir -p /plugins/erigon/build/bin
# WORKDIR /plugins
# COPY --from=builder-elixir /mix/erigon ./erigon
# RUN cd erigon && make evm-prod


#================
#Deployment Stage
#================
FROM elixir:1.13.4-otp-25 as deployer
# RUN mkdir -p /app/test /app/prod

RUN apt-get update && apt-get install -y git bash curl netcat-traditional && apt-get clean && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /app/_build /app/config /app/deps /app/lib /app/plugins /app/priv node/test /app/test-data /app/evm-out

# used in case alpine image are used
# RUN apk update && apk add --no-cache git=2.36.3-r0 bash=5.1.16-r2 curl=7.83.1-r4 go=1.18.7-r0 make=4.3-r0 gcc=11.2.1_git20220219-r2
WORKDIR /app
RUN mix local.hex --force

COPY --from=builder-elixir /mix/erigon/build/bin/ /app/plugins/
COPY --from=builder-elixir /mix/_build /app/_build
COPY --from=builder-elixir /mix/config /app/config
COPY --from=builder-elixir /mix/deps /app/deps
COPY --from=builder-elixir /mix/lib /app/lib
COPY --from=builder-elixir /mix/priv /app/priv
COPY --from=builder-elixir /mix/mix.exs /app/
COPY --from=builder-elixir /mix/mix.lock /app/
COPY --from=builder-elixir /mix/_build/dev/rel/rudder/ /app/prod/
COPY --from=builder-elixir /mix/test/ /app/test
COPY --from=builder-elixir /mix/test-data/ /app/test-data


RUN chmod +x /app/plugins/evm

# Used only for testing in compose
# CMD [ "mix", "test", "./test/block_specimen_decoder_test.exs", "./test/block_result_uploader_test.exs"]

CMD ["/app/prod/bin/rudder", "start"]