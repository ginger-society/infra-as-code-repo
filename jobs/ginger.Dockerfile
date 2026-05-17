FROM debian:bullseye-slim

RUN apt-get update && apt-get install -y \
    libssl1.1 \
    libpq5 \
    libgcc1 \
    libc6 \
    libssl-dev \
    ca-certificates \
    curl \
    && rm -rf /var/lib/apt/lists/*

RUN bash -c "$(curl -fsSL https://raw.githubusercontent.com/ginger-society/infra-as-code-repo/main/rust-helpers/install-pipeline-clis.sh)"

RUN ginger-auth --help

# Copy setup script
COPY copy-credentials-to-workspace.sh /usr/local/bin/copy-credentials-to-workspace.sh
RUN chmod +x /usr/local/bin/copy-credentials-to-workspace.sh