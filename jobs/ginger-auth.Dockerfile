FROM debian:bullseye-slim

RUN echo "deb http://snapshot.debian.org/archive/debian-security/20250901T000000Z bullseye-security main" > /etc/apt/sources.list.d/security-snapshot.list \
    && apt-get update -o Acquire::Check-Valid-Until=false && apt-get install -y \
    libssl1.1 \
    libpq5 \
    libgcc1 \
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