#!/bin/bash
set -e

mkdir -p ~/.ssh

cp /workspace/creds/ssh/id_ed25519          ~/.ssh/id_ed25519
cp /workspace/creds/ssh/id_ed25519.pub      ~/.ssh/id_ed25519.pub
cp /workspace/creds/ssh/id_ed25519-cert.pub ~/.ssh/id_ed25519-cert.pub
cp /workspace/creds/ssh/config              ~/.ssh/config

chmod 700 ~/.ssh
chmod 600 ~/.ssh/id_ed25519
chmod 644 ~/.ssh/config