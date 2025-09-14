FROM node:22-alpine

RUN apk add --no-cache openssh bash shadow

WORKDIR /app
COPY package.json package-lock.json* ./
RUN npm ci --omit=dev || npm i --omit=dev

COPY server.js start.sh ./
# Optional: include repo-side authorized_keys if you use OPTION A
COPY authorized_keys /app/authorized_keys

RUN chmod +x /app/start.sh \
 && sed -i 's/#PubkeyAuthentication yes/PubkeyAuthentication yes/' /etc/ssh/sshd_config \
 && sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config \
 && echo 'Port 2222\nListenAddress 127.0.0.1\nPermitRootLogin no\n' >> /etc/ssh/sshd_config

ENV PORT=8080 \
    WS_PATH=/app53 \
    BACKEND_HOST=127.0.0.1 \
    BACKEND_PORT=2222 \
    SSH_USER=n4

EXPOSE 8080
CMD ["/app/start.sh"]