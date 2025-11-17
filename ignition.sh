#!/usr/bin/env bash
# Author: 4ndr0666 
# set -euo pipefail
# ====================== // IGNITION.SH //
# Description: Multi‑arch builder and launcher for the ars0n-framework-v2-pi , builds all services for both amd64 and
#                    arm64 platforms, and launches the stack via docker compose. It is safe
#                    to run repeatedly; previous containers are brought down automatically.
#                    Paths and package names are Pi 4 + Kali/Ubuntu ARM64 compatible.
# -------------------------------------------------------------------------
REPO_URL="https://github.com/4ndr0666/ars0n-framework-v2-pi"
ARCHIVE_URL="${REPO_URL}/archive/refs/heads/main.zip"
ARCHIVE_NAME="main.zip"
EXTRACTED_DIR="ars0n-framework-v2-pi-main"

if [ ! -d "${EXTRACTED_DIR}" ]; then
  echo "[+] Downloading latest framework release..."
  wget -O "${ARCHIVE_NAME}" "${ARCHIVE_URL}"
  unzip -o "${ARCHIVE_NAME}"
  rm -f "${ARCHIVE_NAME}"
fi

cd "${EXTRACTED_DIR}"

echo "[+] Updating and upgrading system packages..."
sudo apt update -y && sudo apt upgrade -y

echo "[+] Installing Docker, Compose, QEMU for multi-arch..."
sudo apt install -y docker.io docker-compose qemu-user-static unzip wget

if ! groups "$USER" | grep -q '\bdocker\b'; then
  echo "[+] Adding user '$USER' to docker group..."
  sudo usermod -aG docker "$USER" || true
  echo "[!] You may need to log out and back in, or run: newgrp docker"
fi

echo "[+] Ensuring Docker service is running..."
sudo systemctl enable docker
sudo systemctl start docker

echo "[+] Detecting local IP address..."
PI_IP=$(hostname -I | awk '{print $1}')
if [[ -z "$PI_IP" ]]; then
  echo "[!] ERROR: Could not detect local IP address. Exiting." >&2
  exit 1
fi
echo "[+] Detected IP: $PI_IP"
mkdir -p client
echo "REACT_APP_SERVER_IP=${PI_IP}" > client/.env

echo "[+] Configuring Docker buildx and QEMU emulation..."
if ! docker buildx inspect ars0nbuilder >/dev/null 2>&1; then
  docker buildx create --name ars0nbuilder --use
fi
docker run --rm --privileged multiarch/qemu-user-static --reset -p yes || true
docker buildx inspect --bootstrap

# Detect host architecture for Docker build
case $(uname -m) in
  x86_64)   DOCKER_PLATFORM="linux/amd64" ;;
  aarch64)  DOCKER_PLATFORM="linux/arm64" ;;
  *)
    echo "[!] ERROR: Unsupported architecture: $(uname -m). Only x86_64 and aarch64 are supported." >&2
    exit 1
    ;;
esac
echo "[+] Detected Docker platform: $DOCKER_PLATFORM"

CORE_SERVICES=( server client ai_service )
TOOL_SERVICES=( subfinder assetfinder katana sublist3r cloud_enum ffuf subdomainizer cewl metabigor httpx gospider dnsx github-recon nuclei shuffledns )

echo "[+] Building core services for $DOCKER_PLATFORM..."
for svc in "${CORE_SERVICES[@]}"; do
  echo "    • Building core: $svc"
  docker buildx build --platform $DOCKER_PLATFORM \
    -t ars0n/$svc:latest "./$svc" --load
done

echo "[+] Building tool services for $DOCKER_PLATFORM..."
for tool in "${TOOL_SERVICES[@]}"; do
  echo "    • Building tool: $tool"
  docker buildx build --platform $DOCKER_PLATFORM \
    -t ars0n/$tool:latest "./docker/$tool" --load
done

echo "[+] Shutting down any existing containers (safe if none running)..."
docker compose down || true

echo "[+] Launching the ars0n framework stack..."
docker compose up -d

echo "[+] Setup complete!"
echo "UI  : http://${PI_IP}:3000"
echo "API : https://${PI_IP}:8443"
