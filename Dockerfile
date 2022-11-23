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

# # Get Ubuntu packages
# RUN apt-get install -y \
#     build-essential \
#     curl

RUN curl https://sh.rustup.rs -sSf | sh -s -- -y
# Add .cargo/bin to PATH
ENV PATH="/root/.cargo/bin:${PATH}"

# test release
RUN rm -Rf _build && \
    mix local.hex --force && \
    mix local.rebar --force && \
    mix deps.get && \
    MIX_ENV=test mix do compile

# dev release
RUN mix release

#================
#Deployment Stage
#================
FROM elixir:1.13.4-otp-25 as deployer
# RUN mkdir -p /node/test /node/prod
RUN mkdir -p /node
WORKDIR /node
RUN mix local.hex --force

COPY --from=builder _build .
# COPY --from=builder deps .
COPY --from=builder mix.exs .
COPY --from=builder mix.lock .
# COPY --from=builder _build/prod/rel/rudder ./prod/
COPY --from=builder test/ .
COPY --from=builder test-data/ .

# USER default
# ENTRYPOINT [ "/bin/bash", "-l", "-c"]
# CMD [ "cd", "node", "&&", "mix", "test"]
ENTRYPOINT [ "./_build/dev/rel/rudder/bin"]
CMD [ "rudder", "start" ] 



# ENTRYPOINT [ "/bin/bash"]
# CMD []

# ENV $NODE_ETHEREUM_MAINNET $BLOCK_RESULT_OPERATOR_PRIVATE_KEY $ERIGON_NODE 