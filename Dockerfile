FROM avvo/elixir-circleci:1.4.5-1g

ENV MIX_ENV=prod

RUN \
  mkdir -p \
    config \
    deps

# Cache elixir deps
COPY mix.exs mix.lock ./
COPY config ./config
COPY deps ./deps

RUN mix do deps.get, deps.compile

COPY . .

WORKDIR assets

RUN npm install

RUN ./node_modules/brunch/bin/brunch b -p

WORKDIR /opt/app
RUN mix phx.digest

RUN mix release --env=prod --verbose
