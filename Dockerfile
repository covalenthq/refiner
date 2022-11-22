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
COPY mix.lock ./mix.lock

# # Update default packages
# RUN apt-get update

# # Get Ubuntu packages
# RUN apt-get install -y \
#     build-essential \
#     curl

RUN curl https://sh.rustup.rs -sSf | sh -s -- -y
# Add .cargo/bin to PATH
ENV PATH="/root/.cargo/bin:${PATH}"

RUN export MIX_ENV=test && \
    rm -Rf _build && \
    mix local.hex --force && \
    mix local.rebar --force && \
    mix deps.get && \
    mix release

# RUN export MIX_ENV=prod && \
#     rm -Rf _build && \
#     mix local.hex --force && \
#     mix local.rebar --force && \
#     mix deps.get && \
#     mix release --env=prod --no-tar

# RUN APP_NAME="rudder" && \
#     RELEASE_DIR="ls -d _build/test/rel/$APP_NAME/releases/*/" && \
#     mkdir /export && \
#     tar -xf "$RELEASE_DIR/$APP_NAME.tar.gz" -C /export

#================
#Deployment Stage
#================
FROM elixir:1.13.4-otp-25 
# RUN mkdir -p /node/test /node/prod
WORKDIR /node
RUN mix local.hex --force

COPY --from=builder _build .
COPY --from=builder deps .
COPY --from=builder mix.exs .
COPY --from=builder mix.lock .
# COPY --from=builder _build/prod/rel/rudder ./prod/
COPY --from=builder test/ .
COPY --from=builder test-data/ .

# USER default
CMD [ "mix", "test"]
# ENTRYPOINT [ "/bin/bash"]

# ENV $NODE_ETHEREUM_MAINNET $BLOCK_RESULT_OPERATOR_PRIVATE_KEY $ERIGON_NODE 