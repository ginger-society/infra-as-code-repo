FROM debian:bookworm-slim

RUN apt-get update && apt-get install -y \
    libssl3 \
    libpq5 \
    libgcc-s1 \
    libc6 \
    libssl-dev \
    ca-certificates \
    curl \
    && rm -rf /var/lib/apt/lists/*

RUN bash -c "$(curl -fsSL https://raw.githubusercontent.com/ginger-society/infra-as-code-repo/main/rust-helpers/installer.sh)" -- ginger-society/ginger-auth:latest

RUN ginger-auth --help

# Copy setup script
COPY copy-credentials-to-workspace.sh /usr/local/bin/copy-credentials-to-workspace.sh
RUN chmod +x /usr/local/bin/copy-credentials-to-workspace.sh