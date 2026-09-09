#!/bin/bash
set -e

# ginger-auth token-login writes to ~/.ssh/ and ~/.ginger-society/
ginger-auth token-login $GINGER_TOKEN

mkdir -p /workspace/creds/ssh

cp ~/.ssh/id_ed25519           /workspace/creds/ssh/id_ed25519
cp ~/.ssh/id_ed25519.pub       /workspace/creds/ssh/id_ed25519.pub
cp ~/.ssh/id_ed25519-cert.pub  /workspace/creds/ssh/id_ed25519-cert.pub

# Static ssh config for the gitolite host — written here since it's
# not something ginger-auth generates, but every downstream step needs it.
cat > /workspace/creds/ssh/config <<'EOF'
Host source
    User git
    HostName source.gingersociety.org
    Port 3333
    IdentityFile ~/.ssh/id_ed25519
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null
EOF

chmod 644 /workspace/creds/ssh/id_ed25519
chmod 644 /workspace/creds/ssh/id_ed25519.pub
chmod 644 /workspace/creds/ssh/id_ed25519-cert.pub
chmod 644 /workspace/creds/ssh/config

# auth.json for ginger-connector
mkdir -p /workspace/creds/ginger-society
cp ~/.ginger-society/auth.json  /workspace/creds/ginger-society/auth.json
chmod 644 /workspace/creds/ginger-society/auth.json

# docker config written by ginger-auth
mkdir -p /workspace/creds/docker
cp ~/.docker/config.json        /workspace/creds/docker/config.json
chmod 644 /workspace/creds/docker/config.json

cp ~/.npmrc   /workspace/creds/.npmrc
cp ~/.pypirc  /workspace/creds/.pypirc
cp ~/.netrc  /workspace/creds/.netrc
chmod 644 /workspace/creds/.npmrc
chmod 644 /workspace/creds/.pypirc
chmod 644 /workspace/creds/.netrc

echo "Credentials written to /workspace/creds"
ls -la /workspace/creds/