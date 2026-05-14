#!/bin/bash
set -e

# Pull credentials from shared workspace into expected locations
cp /workspace/creds/ssh/id_ed25519          ~/.ssh/id_ed25519
cp /workspace/creds/ssh/id_ed25519.pub      ~/.ssh/id_ed25519.pub
cp /workspace/creds/ssh/id_ed25519-cert.pub ~/.ssh/id_ed25519-cert.pub
chmod 600 ~/.ssh/id_ed25519
