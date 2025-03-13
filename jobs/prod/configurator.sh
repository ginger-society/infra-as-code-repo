#!/bin/sh
set -e  # Exit on error

echo "Setting up SSH configuration..."

# Create SSH directory
mkdir -p /workspace/ssh-config/.ssh
chmod 700 /workspace/ssh-config/.ssh

# Configure SSH to disable strict host key checking
cat <<EOF > /workspace/ssh-config/.ssh/config
Host source.gingersociety.org
    User git
    HostName source.gingersociety.org
    Port 3333
    IdentityFile ~/.ssh/id_ed25519
    StrictHostKeyChecking no
    UserKnownHostsFile=/dev/null
EOF

# Ensure correct permissions
chmod 600 /workspace/ssh-config/.ssh/config

# Add host to known_hosts
ssh-keyscan -p 3333 -H source.gingersociety.org > /workspace/ssh-config/.ssh/known_hosts
chmod 644 /workspace/ssh-config/.ssh/known_hosts

echo "SSH setup complete."

cp /workspace/ssh-credentials/id_ed25519 /workspace/ssh-config/.ssh/id_ed25519
cp -r /workspace/ssh-config/.ssh ~/
chmod 600 ~/.ssh/id_ed25519

echo "SSH setup completed successfully."