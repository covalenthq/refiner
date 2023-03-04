#===========
#(Elixir) Build Stage
#===========
FROM elixir:1.13.4-otp-25 as builder-elixir
RUN mkdir -p /mix
WORKDIR /mix

# Install rust tooling
RUN curl https://sh.rustup.rs -sSf | sh -s -- -y
# Add .cargo/bin to PATH
ENV PATH="/root/.cargo/bin:${PATH}"

COPY config ./config
COPY lib ./lib
COPY priv ./priv
COPY test ./test
COPY test-data ./test-data
COPY mix.exs .

# docker test release
RUN mix local.hex --force && \
    mix local.rebar --force && \
    mix deps.get && \
    MIX_ENV=docker mix do compile

# dev (moonbase alpha) release (copy release to next stage from _build) [Enabled with docker compose]
# RUN MIX_ENV=dev mix release

#================
#Deployment Stage
#================
FROM elixir:1.13.4-otp-25 as deployer
# RUN mkdir -p /app/test /app/prod

RUN apt-get update && apt-get install -y git bash curl netcat-traditional && apt-get clean && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /app/_build /app/config /app/deps /app/lib /app/priv node/test /app/test-data
# Install rust tooling
RUN curl https://sh.rustup.rs -sSf | sh -s -- -y
# Add .cargo/bin to PATH
ENV PATH="/root/.cargo/bin:${PATH}"
# used in case alpine image are used
# RUN apk update && apk add --no-cache git=2.36.3-r0 bash=5.1.16-r2 curl=7.83.1-r4 go=1.18.7-r0 make=4.3-r0 gcc=11.2.1_git20220219-r2
WORKDIR /app
RUN mix local.hex --force
RUN mix local.rebar --force

COPY --from=builder-elixir /mix/_build /app/_build
COPY --from=builder-elixir /mix/config /app/config
COPY --from=builder-elixir /mix/deps /app/deps
COPY --from=builder-elixir /mix/lib /app/lib
COPY --from=builder-elixir /mix/priv /app/priv
COPY --from=builder-elixir /mix/mix.exs /app/
COPY --from=builder-elixir /mix/mix.lock /app/
# COPY --from=builder-elixir /mix/_build/dev/rel/rudder/ /app/prod/
COPY --from=builder-elixir /mix/test/ /app/test
COPY --from=builder-elixir /mix/test-data/ /app/test-data

# Used only for testing in compose
# CMD [ "mix", "test", "./test/block_specimen_decoder_test.exs", "./test/block_result_uploader_test.exs"]

CMD ["/app/prod/bin/rudder", "start"]