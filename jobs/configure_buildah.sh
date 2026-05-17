#!/bin/bash
set -e

echo "[INFO] Setting up Buildah storage directories..."
mkdir -p /workspace/buildah-cache/storage
mkdir -p /workspace/buildah-cache/runtime

echo "[INFO] Writing storage config..."
cat <<EOF > /workspace/buildah-cache/storage.conf
[storage]
driver = "vfs"
runroot = "/workspace/buildah-cache/runtime"
graphroot = "/workspace/buildah-cache/storage"
EOF

export XDG_RUNTIME_DIR=/workspace/buildah-cache/runtime
export CONTAINERS_STORAGE=/workspace/buildah-cache/storage
export CONTAINERS_STORAGE_CONF=/workspace/buildah-cache/storage.conf

echo "[INFO] Buildah configuration setup complete."
exec "$@"