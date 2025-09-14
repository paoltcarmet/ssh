#!/bin/sh
set -e
set -x  # first deploys အတွက် debug logs

SSH_USER="${SSH_USER:-n4}"
SSH_UID="${SSH_UID:-1000}"
SSH_PORT="${BACKEND_PORT:-2222}"
AUTH_KEY_FILE="/home/$SSH_USER/.ssh/authorized_keys"

# Host keys (idempotent)
ssh-keygen -A

# Alpine OpenSSH: privsep/run dirs
mkdir -p /var/empty/sshd
chmod 755 /var/empty/sshd
mkdir -p /var/run/sshd

# create user if not exists
if ! id "$SSH_USER" >/dev/null 2>&1; then
  adduser -D -h "/home/$SSH_USER" "$SSH_USER"
fi

# ssh dir & perms
mkdir -p "/home/$SSH_USER/.ssh"
chmod 700 "/home/$SSH_USER/.ssh"
chown -R "$SSH_USER:$SSH_USER" "/home/$SSH_USER"

# priority 1: env var SSH_AUTHKEY (Secret Manager)
if [ -n "$SSH_AUTHKEY" ]; then
  echo "$SSH_AUTHKEY" > "$AUTH_KEY_FILE"
# priority 2: repo authorized_keys
elif [ -f "/app/authorized_keys" ]; then
  cp /app/authorized_keys "$AUTH_KEY_FILE"
else
  echo "⚠️ No SSH_AUTHKEY and no /app/authorized_keys found; creating empty authorized_keys."
  touch "$AUTH_KEY_FILE"
fi

chmod 600 "$AUTH_KEY_FILE"
chown "$SSH_USER:$SSH_USER" "$AUTH_KEY_FILE"

# harden sshd (idempotent)
grep -q "^Port $SSH_PORT" /etc/ssh/sshd_config || echo "Port $SSH_PORT" >> /etc/ssh/sshd_config
grep -q "^ListenAddress 127.0.0.1" /etc/ssh/sshd_config || echo "ListenAddress 127.0.0.1" >> /etc/ssh/sshd_config
sed -i 's/#PubkeyAuthentication yes/PubkeyAuthentication yes/' /etc/ssh/sshd_config || true
sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config || true
echo "PermitRootLogin no" >> /etc/ssh/sshd_config

# validate config, then start sshd in background
/usr/sbin/sshd -t
/usr/sbin/sshd -D -e &

# Start WS bridge (foreground for Cloud Run)
node server.js
