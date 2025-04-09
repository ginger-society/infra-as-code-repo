#!/bin/bash
set -e

echo "[INFO] Setting up Buildah cache directories..."

mkdir -p "$CONTAINERS_STORAGE"
mkdir -p "$XDG_RUNTIME_DIR"

echo "[INFO] Writing storage configuration to $CONTAINERS_STORAGE_CONF..."

cat <<EOF > "$CONTAINERS_STORAGE_CONF"
[storage]
driver = "vfs"
runroot = "$XDG_RUNTIME_DIR"
graphroot = "$CONTAINERS_STORAGE"
[storage.options]
additionalimagestores = ["/workspace/buildah-cache/containers/cache"]
EOF

echo "[INFO] Buildah configuration setup complete."

# Optional: Start an interactive shell or perform a build
exec "$@"
