import http from "http";
import net from "net";
import { WebSocketServer } from "ws";

const PORT = Number(process.env.PORT || 8080);
const BACKEND_HOST = process.env.BACKEND_HOST || "127.0.0.1";
const BACKEND_PORT = Number(process.env.BACKEND_PORT || 2222);
const WS_PATH = process.env.WS_PATH || "/app53";

const server = http.createServer((req, res) => {
  if (req.url === "/" || req.url === "/healthz") {
    res.writeHead(200, { "Content-Type": "text/plain" });
    return res.end("OK");
  }
  res.writeHead(404);
  res.end("Not Found");
});

const wss = new WebSocketServer({ noServer: true });

wss.on("connection", (ws) => {
  const sock = net.connect({ host: BACKEND_HOST, port: BACKEND_PORT });

  sock.on("connect", () => {
    ws.on("message", (msg) => sock.write(msg));
    ws.on("close", () => sock.destroy());
    ws.on("error", () => sock.destroy());

    sock.on("data", (d) => ws.send(d));
    sock.on("close", () => { try { ws.close(); } catch {} });
    sock.on("error", () => { try { ws.close(); } catch {} });
  });

  sock.on("error", (e) => {
    console.error("TCP error:", e?.message || e);
    try { ws.close(); } catch {}
  });
});

server.on("upgrade", (req, socket, head) => {
  if (req.url !== WS_PATH) {
    socket.write("HTTP/1.1 404 Not Found\r\n\r\n");
    socket.destroy();
    return;
  }
  wss.handleUpgrade(req, socket, head, (ws) => {
    wss.emit("connection", ws, req);
  });
});

server.listen(PORT, "0.0.0.0", () => {
  console.log(`READY: http://0.0.0.0:${PORT}  WS ${WS_PATH}  SSH -> ${BACKEND_HOST}:${BACKEND_PORT}`);
});
