#/usr/bin/env bash
#
# ignition.sh — Multi‑arch builder and launcher for the ars0n framework (v2)
#
# This script provisions Docker and buildx, generates the React .env file
# with the Pi's local IP address, builds all services for both amd64 and
# arm64 platforms, and launches the stack via docker compose.  It is safe
# to run repeatedly; previous containers are brought down automatically.
#
# Usage:
#   ./ignition.sh
#
# Author: 4ndr0666 (updated by ChatGPT)

set -euo pipefail

echo "[+] Updating system packages…"
sudo apt update -y && sudo apt upgrade -y

echo "[+] Installing Docker, Compose and qemu-user-static for multi‑arch builds…"
sudo apt install -y docker.io docker-compose qemu-user-static

echo "[+] Enabling Docker service…"
sudo systemctl enable docker
sudo systemctl start docker

echo "[+] Adding current user to docker group…"
sudo usermod -aG docker "$USER" || true

echo "[+] Detecting local IP address…"
PI_IP=$(hostname -I | awk '{print $1}')
if [[ -z "$PI_IP" ]]; then
  echo "[!] ERROR: Could not detect local IP address. Exiting." >&2
  exit 1
fi
echo "[+] Detected IP: $PI_IP"

echo "[+] Writing frontend .env file…"
mkdir -p client
cat > client/.env <<EOF
REACT_APP_SERVER_IP=${PI_IP}
EOF

echo "[+] Configuring Docker buildx for multi‑architecture builds…"
# Create a buildx builder if it doesn't already exist
if ! docker buildx inspect ars0nbuilder >/dev/null 2>&1; then
  docker buildx create --name ars0nbuilder --use
fi
# Ensure QEMU emulators are registered and bootstrap the builder
docker run --rm --privileged multiarch/qemu-user-static --reset -p yes || true
docker buildx inspect --bootstrap

echo "[+] Building core services (server, client, ai_service)…"
CORE_SERVICES=( server client ai_service )
for svc in "${CORE_SERVICES[@]}"; do
  echo "    • $svc"
  docker buildx build \
    --platform linux/amd64,linux/arm64 \
    -t ars0n/$svc:latest \
    "./$svc" \
    --load
done

echo "[+] Building tool containers…"
TOOL_SERVICES=( subfinder assetfinder katana sublist3r cloud_enum ffuf subdomainizer cewl metabigor httpx gospider dnsx github-recon nuclei shuffledns )
for tool in "${TOOL_SERVICES[@]}"; do
  echo "    • $tool"
  docker buildx build \
    --platform linux/amd64,linux/arm64 \
    -t ars0n/$tool:latest \
    "./docker/$tool" \
    --load
done

echo "[+] Shutting down any existing containers…"
docker compose down || true

echo "[+] Launching the framework…"
docker compose up -d

echo "[+] Setup complete!"
echo "UI available at: http://${PI_IP}:3000"
echo "API available at: https://${PI_IP}:8443"