<p align="center">
  <a href="https://raw.githubusercontent.com/4ndr0666/ars0n-framework-v2-pi/refs/heads/pi-support/assets/badge_build.png"><img src="https://raw.githubusercontent.com/4ndr0666/ars0n-framework-v2-pi/refs/heads/pi-support/assets/badge_build.png" alt="Build Status"></a>
  <a href="https://raw.githubusercontent.com/4ndr0666/ars0n-framework-v2-pi/refs/heads/pi-support/assets/badge_pi.png"><img src="https://raw.githubusercontent.com/4ndr0666/ars0n-framework-v2-pi/refs/heads/pi-support/assets/badge_pi.png" alt="Raspberry Pi"></a>
  <a href="https://raw.githubusercontent.com/4ndr0666/ars0n-framework-v2-pi/refs/heads/pi-support/assets/badge_license.png"><img src="https://raw.githubusercontent.com/4ndr0666/ars0n-framework-v2-pi/refs/heads/pi-support/assets/badge_license.png" alt="License"></a>
</p>

<h1 align="center">Ars0n Framework — Raspberry Pi Edition 🛠️</h1>
<p align="center">ARM64-optimized fork with a hardened, reproducible setup. Fixes the classic “Failed to fetch” by steering the frontend to the Pi’s API IP.</p>

<p align="center">
  <img src="https://raw.githubusercontent.com/4ndr0666/ars0n-framework-v2-pi/refs/heads/pi-support/assets/hero.png" alt="Ars0n Pi Edition Hero" width="860">
</p>

---

## Table of Contents
- [Quick Start](#-quick-start-5-steps)
- [Architecture](#-architecture)
- [Detailed Setup](#-detailed-setup)
- [Ignition Script](#-ignition-script)
- [Autostart on Boot](#-autostart-on-boot)
- [Verification Checklist](#-verification-checklist)
- [Troubleshooting](#-troubleshooting)
- [FAQ](#-faq)

---

## 🚀 Quick Start (5 steps)

1. **Install prerequisites**

   ```bash
   sudo wget https://archive.kali.org/archive-keyring.gpg -O /usr/share/keyrings/kali-archive-keyring.gpg
   Docker + Docker Compose. Ensure your user is in the `docker` group.
   ```
   
3. **Configure frontend environment**  
   Detect your Pi’s LAN IP and inject into the client build:

   ```bash
   PI_IP=$(hostname -I | awk '{print $1}')
   echo "REACT_APP_SERVER_IP=${PI_IP}" > client/.env
   ```

4. **Build & run the stack**

   ```bash
   docker compose down
   docker compose build --no-cache
   docker compose up -d
   ```

5. **Open the app**  
   UI → `http://${PI_IP}:3000`  
   API → `https://${PI_IP}:8443`

6. **(Optional) Enable autostart**  
   See [Autostart on Boot](#-autostart-on-boot).

---

## 🧭 Architecture

<p align="center">
  <img src="https://raw.githubusercontent.com/4ndr0666/ars0n-framework-v2-pi/refs/heads/pi-support/assets/architecture.png" alt="High-level Architecture" width="860">
</p>

**Flow summary**

- **Client** (React) reads `REACT_APP_SERVER_IP` at build time → calls **API** at `https://${IP}:8443`.
- **API** serves requests, talks to **PostgreSQL**, orchestrates modules (assetfinder, gospider, nuclei, etc.).
- All services live on Docker network `ars0n-network`.

**Ports**

- Client → `3000/tcp` (host → container)  
- API → `8443/tcp` (host → container)  
- DB → `5432/tcp` (internal only unless exposed)

---

## 📋 Detailed Setup

### Prereqs & Permissions

- Raspberry Pi 4 (8 GB recommended), ARM64 Linux  
- Docker daemon running  
- Add your user to Docker:

  ```bash
  sudo usermod -aG docker ${USER}
  newgrp docker
  ```

### Configure Frontend → API

Create the `.env` **before** building:

```bash
PI_IP=$(hostname -I | awk '{print $1}')
echo "REACT_APP_SERVER_IP=${PI_IP}" > client/.env
```

This writes:

```
REACT_APP_SERVER_IP=192.168.1.92
```

### Build & Run

```bash
docker compose down
docker compose build --no-cache
docker compose up -d
```

---

## 🔥 Ignition Script

Automates IP detection, environment generation, and deployment.  
Save as `ignition.sh` in repo root, make it executable (`chmod +x ignition.sh`), then run:

```bash
#!/usr/bin/env bash
# Author: 4ndr0666
set -e
# ================ // IGNITION.SH //
# Description: A simple shell script to setup and install
#              the ars0n framework v2 pi-support
# ---------------------------------------------------

# Update & Install Docker
sudo apt update -y && sudo apt upgrade -y
sudo apt-get update -y && sudo apt-get upgrade -y
sudo apt install docker.io docker-compose

# SystemD
sudo systemctl start docker
sudo systemctl enable docker

# Groups
sudo groupadd docker
sudo usermod -aG docker $USER
newgrp docker

# Framework
cd $HOME
wget "https://github.com/R-s0n/ars0n-framework-v2/releases/download/beta-0.0.1/ars0n-framework-v2-beta-0.0.1.zip"
cd ars0n-framework-v2

# Set IP
echo "[+] Detecting Pi IP address..."
PI_IP=$(hostname -I | awk '{print $1}')
if [ -z "$PI_IP" ]; then
  echo "Error: Could not detect local IP address. Exiting."
  exit 1
fi
echo "Detected IP: $PI_IP"

# React Server Setup
echo "[+] Writing frontend env configuration (client/.env)..."
mkdir -p client
cat > client/.env <<EOF
REACT_APP_SERVER_IP=${PI_IP}
EOF

# Docker
echo "[+] Shutting down any existing containers..."
docker compose down || true

echo "[+] Building containers..."
docker-compose up build || docker builder prune && docker-compose build --no-cache

echo "[+] Starting containers..."
docker compose up -d

echo "[+] Setup complete."
echo "UI  : http://${PI_IP}:3000"
echo "API : https://${PI_IP}:8443"
```

<p align="center">
  <img src="https://raw.githubusercontent.com/4ndr0666/ars0n-framework-v2-pi/refs/heads/pi-support/assets/ignition_flow.png" alt="Ignition Flow" width="720">
</p>

---

## 🧷 Autostart on Boot

Create `/etc/systemd/system/ars0n.service`:

```ini
[Unit]
Description=Ars0n Framework Service
Requires=docker.service
After=network-online.target docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
User=${USER}
Group=${USER}
WorkingDirectory=/path/to/your/repo
ExecStart=/usr/bin/docker compose up -d --build
ExecStop=/usr/bin/docker compose down
Restart=on-failure
RestartSec=10s

[Install]
WantedBy=multi-user.target
```

Enable it:

```bash
sudo systemctl daemon-reload
sudo systemctl enable --now ars0n.service
```

---

## ✅ Verification Checklist

- [ ] `client/.env` exists and contains `REACT_APP_SERVER_IP=<Pi IP>`  
- [ ] `docker compose up -d` completes without errors  
- [ ] `docker compose ps` shows `client`, `api`, `db` as `Up`  
- [ ] UI reachable at `http://${PI_IP}:3000`  
- [ ] API reachable at `https://${PI_IP}:8443`  
- [ ] Browser network calls target the Pi IP (not `127.0.0.1`)

---

## 🛠️ Troubleshooting

| Symptom | Root Cause | Fix |
|----------|-------------|-----|
| “Failed to fetch” / import fails | Frontend still points to `127.0.0.1` | Recreate `.env`, rebuild, confirm requests hit `https://${IP}:8443`. |
| CORS error in browser | API not allowing frontend origin | Allow CORS for `http://${PI_IP}:3000`. |
| UI loads but actions fail | API unreachable / wrong protocol | `curl -k https://${PI_IP}:8443/` to verify API; adjust protocol or cert. |
| Nothing on `:3000` | Client binds only to localhost | Ensure it listens on `0.0.0.0` in config. |
| DB errors | Database not ready / bad credentials | Check `docker compose logs db` and API’s `DATABASE_URL`. |

Logs:
```bash
docker compose logs client
docker compose logs api
docker compose logs db
```

Network & ports:
```bash
docker compose ps
ss -tulpen | grep -E '(:3000|:8443)'
```

---

## ❓ FAQ

**Q:** Do I need to edit the compose file for my IP?  
**A:** No. Run `./ignition.sh` or manually create `.env` before building.

**Q:** Can I change the UI port?  
**A:** Yes. Edit the `client` service `ports` mapping in `docker-compose.yml`.

**Q:** Will this work on non-Pi hosts?  
**A:** Yes, provided the environment variable points to the correct host IP.

---

## 📦 Client Snippet (Reference)

```yaml
client:
  container_name: ars0n-framework-v2-client-1
  build:
    context: ./client
    args:
      REACT_APP_SERVER_IP: 192.168.1.92
  ports:
    - "3000:3000"
  depends_on:
    - api
  restart: unless-stopped
  networks:
    - ars0n-network
```

> Ensure your full compose file matches this pattern.

---

<p align="center">
  <img src="https://raw.githubusercontent.com/4ndr0666/ars0n-framework-v2-pi/refs/heads/pi-support/assets/footer.png" alt="Footer" width="680">
</p>
