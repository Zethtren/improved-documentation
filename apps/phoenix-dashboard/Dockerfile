# Stage 1: Build
FROM elixir:1.17-alpine AS builder

RUN apk add --no-cache build-base git nodejs npm

WORKDIR /app

ENV MIX_ENV=prod

COPY mix.exs mix.lock ./
RUN mix local.hex --force && mix local.rebar --force
RUN mix deps.get --only prod
RUN mix deps.compile

COPY config config
COPY lib lib
COPY assets assets
COPY priv priv

RUN mix assets.deploy
RUN mix compile
RUN mix release

# Stage 2: Runtime (must match builder Alpine version for OpenSSL compatibility)
FROM alpine:3.22

RUN apk add --no-cache libstdc++ openssl ncurses-libs

WORKDIR /app
COPY --from=builder /app/_build/prod/rel/phoenix_dashboard ./

ENV PHX_HOST=admin.localhost
ENV PORT=4000
ENV SECRET_KEY_BASE=generate-a-real-one-for-prod

EXPOSE 4000

CMD ["bin/phoenix_dashboard", "start"]
