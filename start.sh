#!/bin/sh
set -e

SSH_USER="${SSH_USER:-n4}"
SSH_PORT="${BACKEND_PORT:-2222}"
AUTH_KEY_FILE="/home/$SSH_USER/.ssh/authorized_keys"

# 1) Start Node first (foreground) for Cloud Run startup probe
node server.js &
NODE_PID=$!

# 2) Prepare sshd in background
(
  set -e
  ssh-keygen -A
  mkdir -p /var/empty/sshd /var/run/sshd
  chmod 755 /var/empty/sshd

  # user
  if ! id "$SSH_USER" >/dev/null 2>&1; then
    adduser -D -h "/home/$SSH_USER" "$SSH_USER"
  fi
  mkdir -p "/home/$SSH_USER/.ssh"
  chmod 700 "/home/$SSH_USER/.ssh"
  chown -R "$SSH_USER:$SSH_USER" "/home/$SSH_USER"

  # authorized_keys: Secret > repo > empty
  if [ -n "$SSH_AUTHKEY" ]; then
    echo "$SSH_AUTHKEY" > "$AUTH_KEY_FILE"
  elif [ -f "/app/authorized_keys" ]; then
    cp /app/authorized_keys "$AUTH_KEY_FILE"
  else
    echo "# provide SSH_AUTHKEY or mount authorized_keys" > "$AUTH_KEY_FILE"
  fi
  chmod 600 "$AUTH_KEY_FILE"
  chown "$SSH_USER:$SSH_USER" "$AUTH_KEY_FILE"

  # sshd config (idempotent)
  grep -q "^Port $SSH_PORT" /etc/ssh/sshd_config || echo "Port $SSH_PORT" >> /etc/ssh/sshd_config
  grep -q "^ListenAddress 127.0.0.1" /etc/ssh/sshd_config || echo "ListenAddress 127.0.0.1" >> /etc/ssh/sshd_config
  sed -i 's/#PubkeyAuthentication yes/PubkeyAuthentication yes/' /etc/ssh/sshd_config || true
  sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config || true
  echo "PermitRootLogin no" >> /etc/ssh/sshd_config

  /usr/sbin/sshd -t || echo "⚠️ sshd test warnings"
  /usr/sbin/sshd -D -e
) &

# 3) keep container on Node
wait "$NODE_PID"