# Stage 1: Install cargo-leptos (cached layer)
FROM rust:slim-bookworm AS toolchain

RUN apt-get update && apt-get install -y pkg-config libssl-dev perl make && rm -rf /var/lib/apt/lists/*
RUN rustup target add wasm32-unknown-unknown
RUN cargo install cargo-leptos@0.3.6

# Stage 2: Build the app
FROM toolchain AS builder

WORKDIR /app
COPY Cargo.toml Cargo.lock ./
COPY src/ src/
COPY style.css index.html ./

RUN cargo update
ENV LEPTOS_WASM_OPT_VERSION=version_129
RUN cargo leptos build --release

# Stage 3: Runtime
FROM debian:bookworm-slim

RUN apt-get update && apt-get install -y ca-certificates libssl3 && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY --from=builder /app/target/release/leptos-cv ./
COPY --from=builder /app/target/site ./site

ENV LEPTOS_SITE_ADDR=0.0.0.0:8080
ENV LEPTOS_SITE_ROOT=site
EXPOSE 8080

CMD ["./leptos-cv"]
