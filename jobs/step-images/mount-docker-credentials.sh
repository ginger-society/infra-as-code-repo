#!/bin/bash
set -e

# Restore docker config so buildah finds the registry credentials
mkdir -p ~/.docker
cp /workspace/creds/docker/config.json ~/.docker/config.json
