FROM quay.io/buildah/stable:latest

# Set environment variables for Buildah configuration
ENV XDG_RUNTIME_DIR=/workspace/buildah-cache \
    CONTAINERS_STORAGE=/workspace/buildah-cache \
    CONTAINERS_STORAGE_CONF=/workspace/buildah-cache/storage.conf

# Copy setup script
COPY configure_buildah.sh /usr/local/bin/configure_buildah.sh
RUN chmod +x /usr/local/bin/configure_buildah.sh

COPY mount-docker-credentials.sh /usr/local/bin/mount-docker-credentials.sh
RUN chmod +x /usr/local/bin/mount-docker-credentials.sh


