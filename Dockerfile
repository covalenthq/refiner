#===========
#(Elixir) Build Stage
#===========
FROM elixir:1.17-otp-27-alpine as builder-elixir

# Install git and build essentials
RUN apk add --no-cache git build-base

RUN mkdir -p /mix
WORKDIR /mix

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
FROM elixir:1.17-otp-27-alpine as deployer
# RUN mkdir -p /app/test /app/prod

RUN apk add --no-cache git bash curl netcat-openbsd build-base && rm -rf /var/cache/apk/*

RUN mkdir -p /mix/_build /mix/config /mix/deps /mix/lib /mix/priv node/test /mix/test-data

WORKDIR /app
RUN mix local.hex --force
RUN mix local.rebar --force

COPY --from=builder-elixir /mix/_build /mix/_build
COPY --from=builder-elixir /mix/config /mix/config
COPY --from=builder-elixir /mix/deps /mix/deps
COPY --from=builder-elixir /mix/lib /mix/lib
COPY --from=builder-elixir /mix/priv /mix/priv
COPY --from=builder-elixir /mix/mix.exs /mix/
COPY --from=builder-elixir /mix/mix.lock /mix/
# COPY --from=builder-elixir /mix/_build/dev/rel/refiner/ /mix/prod/
COPY --from=builder-elixir /mix/test/ /mix/test
COPY --from=builder-elixir /mix/test-data/ /mix/test-data

# Used only for testing in compose
# CMD [ "mix", "test", "./test/block_specimen_decoder_test.exs", "./test/block_result_uploader_test.exs"]

CMD ["/mix/prod/bin/refiner", "start"]

EXPOSE 9568