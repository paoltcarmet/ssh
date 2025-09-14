<div align="center">

# 🔴⚫🟡 N4SSH (Cloud Run)

[![Docker](https://img.shields.io/badge/Docker-n4vip/n4ssh-blue)](https://hub.docker.com/r/n4vip/n4ssh)
![Cloud Run](https://img.shields.io/badge/Platform-Google%20Cloud%20Run-4285F4)
![Protocol](https://img.shields.io/badge/Ingress-HTTPS%2FWebSocket-informational)
![Backend](https://img.shields.io/badge/Backend-Built--in%20SSHD-success)
![License](https://img.shields.io/badge/License-MIT-green)

**Client (SSH over WebSocket)** ⇄ **Cloud Run (WS bridge + sshd)**  

🚀 VPS မလိုဘဲ Cloud Run ထဲမှာပဲ SSH shell run လုပ်နိုင်အောင်  
N4SSH ကို တည်ဆောက်ထားပါတယ် ✅

</div>

---

## ✨ အထူးအချက်များ
- Cloud Run container ထဲမှာပဲ `sshd` ပါပြီးသား  
- Client က `wss://<service>.run.app/app53` နဲ့ ချိတ်မယ်  
- **VPS မလို** – ephemeral shell (Cloud Run container) ကို ချိတ်သုံးလို့ရ

---

## 🏗️ Architecture 
---

## ⚙️ Env Variables
- `WS_PATH` → default `/app53`
- `BACKEND_HOST` → `127.0.0.1`
- `BACKEND_PORT` → `2222`
- `SSH_USER` → default `n4`
- `SSH_AUTHKEY` → Public SSH Key (Secret Manager ထဲသိမ်းထားဖို့ အကြံပြု)

---

## 🚀 Deploy (Cloud Run)
```bash
gcloud run deploy n4ssh \
  --image=docker.io/n4vip/n4ssh:latest \
  --region=us-central1 \
  --platform=managed \
  --allow-unauthenticated \
  --port=8080 \
  --timeout=3600 \
  --concurrency=10 \
  --max-instances=30 \
  --set-env-vars=WS_PATH=/app53,BACKEND_HOST=127.0.0.1,BACKEND_PORT=2222,SSH_USER=n4 \
  --set-secrets=SSH_AUTHKEY=projects/_/secrets/SSH_AUTHKEY:latest
