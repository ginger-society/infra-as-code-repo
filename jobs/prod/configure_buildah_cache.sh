#!/bin/sh
set -e  # Exit on error
echo "Configuring Buildah storage..."

export XDG_RUNTIME_DIR="/workspace/buildah-cache"
export CONTAINERS_STORAGE="/workspace/buildah-cache"
export CONTAINERS_STORAGE_CONF="$XDG_RUNTIME_DIR/storage.conf"

mkdir -p "$CONTAINERS_STORAGE"
mkdir -p "$XDG_RUNTIME_DIR"

# Create a default storage.conf file with vfs instead of overlay
cat <<EOF > "$CONTAINERS_STORAGE_CONF"
[storage]
driver = "vfs"
runroot = "$XDG_RUNTIME_DIR"
graphroot = "$CONTAINERS_STORAGE"
[storage.options]
additionalimagestores = ["/workspace/buildah-cache/containers/cache"]
EOF