# Dockerfile.build
FROM rust:1-slim-bullseye

RUN apt update && apt install -y docker.io pkg-config libssl-dev gcc-mingw-w64-x86-64

RUN rustup target add x86_64-pc-windows-gnu
RUN rustup target add aarch64-unknown-linux-gnu
RUN rustup target add aarch64-apple-darwin
RUN rustup target add x86_64-unknown-linux-gnu
RUN rustup target add x86_64-apple-darwin
