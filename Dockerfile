FROM avvo/elixir-circleci:1.5.2-1c

ENV REPLACE_OS_VARS=true
ENV MIX_ENV=prod
WORKDIR /opt/app/snapeth-worker

RUN \
  mkdir -p \
    config \
    deps

# Cache elixir deps
COPY mix.exs mix.lock ./
COPY config ./config
RUN mix do deps.get, deps.compile

# Compile source files
COPY . .
RUN mix release --env=prod --verbose
CMD /opt/app/snapeth-worker/_build/prod/rel/snapeth/bin/snapeth foreground
