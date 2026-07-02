FROM python:3.12-slim

RUN apt-get update \
    && apt-get install -y --no-install-recommends util-linux \
    && rm -rf /var/lib/apt/lists/* \
    && pip install --no-cache-dir twine

COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Non-root user; this image only needs read access to the mounted PVC
# and network egress to upload.pypi.org.
RUN useradd -m -u 10001 syncer
USER syncer

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]