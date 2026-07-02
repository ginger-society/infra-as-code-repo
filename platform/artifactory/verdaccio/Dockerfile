FROM node:20-slim

RUN apt-get update \
    && apt-get install -y --no-install-recommends util-linux tar \
    && rm -rf /var/lib/apt/lists/*

COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Non-root user; this image only needs read access to the mounted PVC
# and network egress to registry.npmjs.org.
RUN useradd -m -u 10001 syncer
USER syncer
ENV HOME=/home/syncer

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]