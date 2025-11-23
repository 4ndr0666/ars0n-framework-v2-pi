#!/usr/bin/env bash
# ignition.sh — FINAL 2025 Pi-Native Gold Standard
# Author: 4ndr0666 + Ψ-4ndr0666
# Pure Raspberry Pi 4/5 ARM64 deployment — NO ZIP, NO EXTRACTED DIR, NO QEMU
# React env var baked at BUILD TIME → white screen permanently dead
# This script MUST be run from the real git clone (not the zip)

set -euo pipefail

# ────────────────────────────────────────────────────────────────
# 1. Verify we are in the REAL repo (not the cursed zip)
# ────────────────────────────────────────────────────────────────
if [ ! -d ".git" ]; then
  echo "[!] FATAL: This script must be run from the real git clone!"
  echo "    You are in a broken extracted zip."
  echo "    Fix: cd ~/ars0n-framework-v2-pi && ./ignition.sh --ai"
  exit 1
fi

echo "[Ψ] Real repo confirmed — ascension guaranteed"

# ────────────────────────────────────────────────────────────────
# 2. System prep
# ────────────────────────────────────────────────────────────────
echo "[Ψ] Updating Kali + installing dependencies..."
sudo apt update -y && sudo apt upgrade -y
sudo apt install -y docker.io docker-compose openssl wget curl ca-certificates --no-install-recommends

# Docker group
if ! groups "$USER" | grep -q '\bdocker\b'; then
  sudo usermod -aG docker "$USER"
  echo "[Ψ] Added $USER to docker group — run 'newgrp docker' or relog"
fi

sudo systemctl enable --now docker >/dev/null 2>&1

# ────────────────────────────────────────────────────────────────
# 3. Detect Pi IP
# ────────────────────────────────────────────────────────────────
PI_IP=$(hostname -I | awk '{print $1}')
if [[ -z "$PI_IP" ]]; then
  echo "[!] FATAL: No IP detected. Check network." >&2
  exit 1
fi
echo "[Ψ] Pi IP locked: $PI_IP"

# ────────────────────────────────────────────────────────────────
# 4. Generate self-signed certs
# ────────────────────────────────────────────────────────────────
mkdir -p server/certs
if [ ! -f server/certs/cert.pem ]; then
  echo "[Ψ] Forging TLS certs for https://$PI_IP:8443..."
  openssl req -x509 -nodes -days 3650 -newkey rsa:4096 \
    -keyout server/certs/key.pem \
    -out server/certs/cert.pem \
    -subj "/CN=${PI_IP}" -addext "subjectAltName=IP:${PI_IP}" >/dev/null 2>&1
fi

# ────────────────────────────────────────────────────────────────
# 5. Purge old stack
# ────────────────────────────────────────────────────────────────
echo "[Ψ] Voiding previous containers..."
docker compose down --remove-orphans || true

if [[ "$*" == *"--reset-db"* ]]; then
  echo "[Ψ] --reset-db → nuking postgres volume..."
  docker volume rm ars0n-framework-v2-pi_postgres_data 2>/dev/null || true
  docker volume rm ars0n-framework-v2_postgres_data 2>/dev/null || true
fi

# ────────────────────────────────────────────────────────────────
# 6. BUILD CORE SERVICES — REAL FILES ONLY
# ────────────────────────────────────────────────────────────────
echo "[Ψ] Building core services (native arm64)..."

docker build -t ars0n/server:latest ./server

echo "[Ψ] Baking REACT_APP_SERVER_IP=$PI_IP into frontend bundle..."
docker build \
  --build-arg REACT_APP_SERVER_IP=$PI_IP \
  --build-arg REACT_APP_SERVER_PROTOCOL=https \
  -t ars0n/client:latest \
  ./client

docker build -t ars0n/ai:3.13 ./ai_service

echo "[Ψ] Building recon swarm..."
for tool in docker/*/; do
  name=$(basename "$tool")
  echo " • $name"
  docker build -q -t ars0n/$name:latest "$tool"
done

# ────────────────────────────────────────────────────────────────
# 7. Launch stack
# ────────────────────────────────────────────────────────────────
echo "[Ψ] Igniting full stack..."
docker compose up -d

if [[ "$*" == *"--ai"* ]] || [[ "$*" == *"--with-ai"* ]]; then
  echo "[Ψ] --ai flag → deploying AI service..."
  docker compose --profile ai up -d --force-recreate ai_service
fi

# ────────────────────────────────────────────────────────────────
# 8. Systemd autostart
# ────────────────────────────────────────────────────────────────
SERVICE_FILE="/etc/systemd/system/ars0n-framework.service"
CURRENT_DIR=$(pwd)

cat <<EOT | sudo tee "$SERVICE_FILE" > /dev/null
[Unit]
Description=Ars0n Framework V2 (Pi Native Gold)
After=network-online.target docker.service
Requires=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=$CURRENT_DIR
User=$USER
Group=docker
ExecStart=/usr/bin/docker compose up -d
ExecStartPost=/usr/bin/docker compose --profile ai up -d ai_service 2>/dev/null || true
ExecStop=/usr/bin/docker compose down
TimeoutStartSec=300

[Install]
WantedBy=multi-user.target
EOT

sudo systemctl daemon-reload
sudo systemctl enable --now ars0n-framework.service >/dev/null 2>&1

# ────────────────────────────────────────────────────────────────
# 9. ASCENSION COMPLETE
# ────────────────────────────────────────────────────────────────
echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║                  Ψ ARS0N FRAMEWORK V2 LIVE                  ║"
echo "║                                                              ║"
echo "║  Web UI      → http://$PI_IP:3000                         ║"
echo "║  API HTTPS   → https://$PI_IP:8443                       ║"
echo "║  AI Service  → http://$PI_IP:8000 (if --ai used)         ║"
echo "║                                                              ║"
echo "║  Rebuild UI  → docker build --build-arg REACT_APP_SERVER_IP=$(hostname -I | awk '{print \$1}') -t ars0n/client:latest ./client && docker compose up -d --force-recreate client ║"
echo "║  Reset DB    → ./ignition.sh --reset-db                     ║"
echo "║  Enable AI   → ./ignition.sh --ai                            ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""
echo "[Ψ] The Pi has transcended hardware."
echo "[Ψ] The leaks are eternal."

exit 0
