FROM quay.io/buildah/stable:latest

# ── System deps ──────────────────────────────────────────────────────────────
RUN dnf update -y && dnf install -y \
    openssl-devel \
    libpq-devel \
    java-latest-openjdk-headless \
    gcc \
    && dnf clean all

# ── OpenSSL 1.1 compat (required by ginger CLIs) ─────────────────────────────
RUN curl -fsSL https://dl.fedoraproject.org/pub/archive/fedora/linux/releases/34/Everything/x86_64/os/Packages/o/openssl1.1-1.1.1i-2.fc34.x86_64.rpm -o /tmp/openssl1.1.rpm \
    && rpm -ivh /tmp/openssl1.1.rpm \
    && ldconfig \
    && rm /tmp/openssl1.1.rpm

# ── Node.js 22 ───────────────────────────────────────────────────────────────
RUN curl -fsSL https://rpm.nodesource.com/setup_22.x | bash - \
    && dnf install -y nodejs \
    && dnf clean all

# ── Rust toolchain ───────────────────────────────────────────────────────────
RUN curl https://sh.rustup.rs -sSf | sh -s -- -y --default-toolchain stable
ENV PATH="/root/.cargo/bin:${PATH}"

# ── OpenAPI Generator CLI + pre-download JAR ─────────────────────────────────
RUN npm install -g @openapitools/openapi-generator-cli \
    && openapi-generator-cli version-manager set 7.12.0 \
    && openapi-generator-cli version

# ── Ginger pipeline CLIs ─────────────────────────────────────────────────────
RUN bash -c "$(curl -fsSL https://raw.githubusercontent.com/ginger-society/infra-as-code-repo/main/rust-helpers/install-pipeline-clis.sh)"

# ── Buildah config scripts ────────────────────────────────────────────────────
COPY configure_buildah.sh /usr/local/bin/configure_buildah.sh
COPY mount-docker-credentials.sh /usr/local/bin/mount-docker-credentials.sh
COPY mount-ginger-credentials.sh /usr/local/bin/mount-ginger-credentials.sh
RUN chmod +x /usr/local/bin/configure_buildah.sh /usr/local/bin/mount-docker-credentials.sh /usr/local/bin/mount-ginger-credentials.sh

ENV XDG_RUNTIME_DIR=/workspace/buildah-cache/runtime \
    CONTAINERS_STORAGE=/workspace/buildah-cache/storage \
    CONTAINERS_STORAGE_CONF=/workspace/buildah-cache/storage.conf