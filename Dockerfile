FROM node:22-alpine

RUN apk add --no-cache openssh bash shadow tini

WORKDIR /app

# Install runtime deps (pin ws present)
COPY package.json ./
RUN npm install --omit=dev && npm install ws@8 --omit=dev

# App
COPY server.js start.sh ./
COPY authorized_keys /app/authorized_keys

# Base sshd config + perms
RUN chmod +x /app/start.sh \
 && sed -i 's/#PubkeyAuthentication yes/PubkeyAuthentication yes/' /etc/ssh/sshd_config \
 && sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config \
 && echo 'Port 2222\nListenAddress 127.0.0.1\nPermitRootLogin no\n' >> /etc/ssh/sshd_config

ENV NODE_ENV=production \
    PORT=8080 \
    WS_PATH=/app53 \
    BACKEND_HOST=127.0.0.1 \
    BACKEND_PORT=2222 \
    SSH_USER=n4

EXPOSE 8080
ENTRYPOINT ["/sbin/tini","--"]
CMD ["/app/start.sh"]