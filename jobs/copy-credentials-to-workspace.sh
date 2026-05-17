#!/bin/bash
set -e

# ginger-auth token-login writes to ~/.ssh/ and ~/.ginger-society/
ginger-auth token-login $GINGER_TOKEN

# Now copy everything ginger-auth generated into the shared creds workspace
mkdir -p /workspace/creds/ssh

# ginger-auth generates these three
cp ~/.ssh/id_ed25519            /workspace/creds/ssh/id_ed25519
cp ~/.ssh/id_ed25519.pub        /workspace/creds/ssh/id_ed25519.pub
cp ~/.ssh/id_ed25519-cert.pub   /workspace/creds/ssh/id_ed25519-cert.pub

# auth.json for ginger-connector
mkdir -p /workspace/creds/ginger-society
cp ~/.ginger-society/auth.json  /workspace/creds/ginger-society/auth.json

# docker config written by ginger-auth
mkdir -p /workspace/creds/docker
cp ~/.docker/config.json        /workspace/creds/docker/config.json

# npmrc and pypirc if your pipeline needs them
cp ~/.npmrc                     /workspace/creds/.npmrc
cp ~/.pypirc                    /workspace/creds/.pypirc

echo "Credentials written to /workspace/creds"