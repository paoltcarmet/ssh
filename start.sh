#!/bin/sh
set -e

# Vars
SSH_USER="${SSH_USER:-n4}"
SSH_UID="${SSH_UID:-1000}"
SSH_PORT="${BACKEND_PORT:-2222}"
AUTH_KEY_FILE="/home/$SSH_USER/.ssh/authorized_keys"

# Ensure sshd host keys exist
ssh-keygen -A

# Create user if not exists
if ! id "$SSH_USER" >/dev/null 2>&1; then
  adduser -D -h "/home/$SSH_USER" "$SSH_USER"
fi

# SSH dir & authorized_keys
mkdir -p "/home/$SSH_USER/.ssh"
chmod 700 "/home/$SSH_USER/.ssh"

if [ -n "$SSH_AUTHKEY" ]; then
  echo "$SSH_AUTHKEY" > "$AUTH_KEY_FILE"
  chmod 600 "$AUTH_KEY_FILE"
  chown -R "$SSH_USER:$SSH_USER" "/home/$SSH_USER/.ssh"
fi

# Harden sshd_config (already appended in Dockerfile, but idempotent)
grep -q "^Port $SSH_PORT" /etc/ssh/sshd_config || echo "Port $SSH_PORT" >> /etc/ssh/sshd_config
grep -q "^ListenAddress 127.0.0.1" /etc/ssh/sshd_config || echo "ListenAddress 127.0.0.1" >> /etc/ssh/sshd_config
sed -i 's/#PubkeyAuthentication yes/PubkeyAuthentication yes/' /etc/ssh/sshd_config
sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
echo "PermitRootLogin no" >> /etc/ssh/sshd_config

# Start sshd (background)
mkdir -p /var/run/sshd
/usr/sbin/sshd

# Start WS bridge (foreground)
node server.js