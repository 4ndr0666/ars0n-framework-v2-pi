<p align="center">
  <a href="https://raw.githubusercontent.com/4ndr0666/ars0n-framework-v2-pi/refs/heads/pi-support/assets/badge_build.png"><img src="https://raw.githubusercontent.com/4ndr0666/ars0n-framework-v2-pi/refs/heads/pi-support/assets/badge_build.png" alt="Build Status"></a>
  <a href="https://raw.githubusercontent.com/4ndr0666/ars0n-framework-v2-pi/refs/heads/pi-support/assets/badge_pi.png"><img src="https://raw.githubusercontent.com/4ndr0666/ars0n-framework-v2-pi/refs/heads/pi-support/assets/badge_pi.png" alt="Raspberry Pi"></a>
  <a href="https://raw.githubusercontent.com/4ndr0666/ars0n-framework-v2-pi/refs/heads/pi-support/assets/badge_license.png"><img src="https://raw.githubusercontent.com/4ndr0666/ars0n-framework-v2-pi/refs/heads/pi-support/assets/badge_license.png" alt="License"></a>
</p>

<h1 align="center">Ars0n Framework — Raspberry Pi Edition 🛠️</h1>
<p align="center">ARM64-optimized, multi-arch ready, reproducible, and designed for Pi 4. Hardened Docker stack, gospider fixed, and frictionless deployment. “Failed to fetch” is dead—frontend always targets the correct API IP.</p>

<p align="center">
  <img src="assets/hero.png" alt="Ars0n Pi Edition Hero" width="860">
</p>

---

## Table of Contents

- [Quick Start](#-quick-start)
- [Architecture](#-architecture)
- [Detailed Setup](#-detailed-setup)
- [Ignition Script](#-ignition-script)
- [Autostart on Boot](#-autostart-on-boot)
- [Verification Checklist](#-verification-checklist)
- [Troubleshooting](#-troubleshooting)
- [FAQ](#-faq)

---

## 🚀 Quick Start

1. **Install prerequisites**

   ```bash
   sudo apt update -y && sudo apt upgrade -y
   sudo apt install -y docker.io docker-compose qemu-user-static
   sudo usermod -aG docker $USER
   ````

Log out and back in (or run `newgrp docker`) to apply group changes.

2. **Download/clone this repository**

   ```bash
   git clone https://github.com/4ndr0666/ars0n-framework-v2-pi.git
   cd ars0n-framework-v2-pi
   ```

3. **Run the ignition script**

   The ignition script automates IP detection, `.env` generation, Docker multi-arch builder setup, image builds, and stack launch:

   ```bash
   chmod +x ignition.sh
   ./ignition.sh
   ```

   This will:

   * Detect your Pi’s LAN IP
   * Generate `client/.env`
   * Initialize Docker buildx (multi-arch builder)
   * Build all core and tooling services for ARM64 + AMD64
   * Launch the full stack

4. **Access the App**

   * UI → `http://<Pi IP>:3000`
   * API → `https://<Pi IP>:8443`

   Your Pi’s IP is detected automatically and set in the client environment.

5. **(Optional) Enable autostart**

   See [Autostart on Boot](#-autostart-on-boot).

---

## 🧭 Architecture

<p align="center">
  <img src="assets/architecture.png" alt="High-level Architecture" width="860">
</p>

* **Client**: React SPA, gets API IP via `client/.env` at build time.
* **API**: Python FastAPI, manages DB and tool orchestration.
* **DB**: ARM64-optimized Postgres 14-alpine.
* **Tools**: All major recon and OSINT tools (built from source, multi-arch).
* **Networking**: Docker bridge `ars0n-network`.

**Key Ports**

* UI (client): `3000/tcp`
* API (server): `8443/tcp`
* DB (internal): `5432/tcp`

---

## 📋 Detailed Setup

**Hardware & OS Requirements**

* Raspberry Pi 4 (8 GB RAM recommended)
* ARM64 Linux (Kali, Ubuntu, Raspbian, etc.)

**Software Prereqs**

* Docker
* Docker Compose
* QEMU (for multi-arch builds)

**Permissions**

```bash
sudo usermod -aG docker $USER
newgrp docker
```

**Frontend API Address**

Automatically configured by `ignition.sh`. To do it manually:

```bash
PI_IP=$(hostname -I | awk '{print $1}')
echo "REACT_APP_SERVER_IP=${PI_IP}" > client/.env
```

**Manual Build/Run (if skipping ignition.sh):**

```bash
docker buildx create --name ars0nbuilder --use || docker buildx use ars0nbuilder
docker buildx inspect --bootstrap
docker compose build
docker compose up -d
```

---

## 🔥 Ignition Script

Full automation: upgrades system, installs Docker/Compose/QEMU, configures multi-arch buildx, sets up the React environment, builds all containers for ARM64 and AMD64, and brings up the stack.

<details>
<summary>View ignition.sh</summary>

```bash
#!/usr/bin/env bash
set -e

echo "[+] Updating system…"
sudo apt update -y && sudo apt upgrade -y

echo "[+] Installing Docker + Compose + QEMU…"
sudo apt install -y docker.io docker-compose qemu-user-static

echo "[+] Enabling Docker…"
sudo systemctl enable docker
sudo systemctl start docker

echo "[+] Adding user to docker group…"
sudo usermod -aG docker "$USER"

PI_IP=$(hostname -I | awk '{print $1}')
if [ -z "$PI_IP" ]; then
    echo "[!] ERROR: Failed to detect local IP"
    exit 1
fi
echo "[+] Detected IP: $PI_IP"

mkdir -p client
cat > client/.env <<EOF
REACT_APP_SERVER_IP=${PI_IP}
EOF
echo "[+] Wrote client/.env"

echo "[+] Setting up multi-arch builder…"
docker buildx create --name ars0nbuilder --use >/dev/null 2>&1 || docker buildx use ars0nbuilder
docker buildx inspect --bootstrap

CORE_SERVICES=( server client ai_service )
for svc in "${CORE_SERVICES[@]}"; do
    echo "[+] Building core service: $svc"
    docker buildx build --platform linux/amd64,linux/arm64 -t ars0n/$svc:latest "./$svc" --load
done

TOOLS=(
    subfinder assetfinder katana sublist3r cloud_enum ffuf
    subdomainizer cewl metabigor httpx gospider dnsx
    github-recon nuclei shuffledns
)
for tool in "${TOOLS[@]}"; do
    echo "[+] Building tool container: $tool"
    docker buildx build --platform linux/amd64,linux/arm64 -t ars0n/$tool:latest "./docker/$tool" --load
done

echo "[+] Shutting down previous containers…"
docker compose down || true

echo "[+] Bringing up framework…"
docker compose up -d

echo ""
echo "[+] Setup complete!"
echo "UI  : http://${PI_IP}:3000"
echo "API : https://${PI_IP}:8443"
```

</details>

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

* [ ] `client/.env` exists and contains `REACT_APP_SERVER_IP=<Pi IP>`
* [ ] `docker compose up -d` completes without errors
* [ ] `docker compose ps` shows all major services as `Up`
* [ ] UI reachable at `http://<Pi IP>:3000`
* [ ] API reachable at `https://<Pi IP>:8443`
* [ ] Tooling containers build and run (`gospider`, etc.)

---

## 🛠️ Troubleshooting

| Symptom                          | Root Cause                           | Fix                                                                     |
| -------------------------------- | ------------------------------------ | ----------------------------------------------------------------------- |
| “Failed to fetch” / import fails | Frontend still points to `127.0.0.1` | Recreate `.env`, rebuild, confirm requests hit `https://${IP}:8443`.    |
| CORS error in browser            | API not allowing frontend origin     | Allow CORS for `http://<Pi IP>:3000`.                                   |
| UI loads but actions fail        | API unreachable / wrong protocol     | `curl -k https://<Pi IP>:8443/` to verify API; adjust protocol or cert. |
| Nothing on `:3000`               | Client binds only to localhost       | Ensure it listens on `0.0.0.0` in config.                               |
| DB errors                        | Database not ready / wrong image     | Use `arm64v8/postgres:14-alpine` and delete old DB volumes.             |

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

**Q:** Will this work on x86 systems?
**A:** Yes—multi-arch builds target both `amd64` and `arm64`.

**Q:** Can I change the UI port?
**A:** Edit the `client` service `ports` mapping in `docker-compose.yml`.

**Q:** How do I add a new tool?
**A:** Add its Dockerfile under `docker/`, append to the TOOLS array in `ignition.sh`, and add a service in `docker-compose.yml`.

---

## 📦 Client Service Example

```yaml
client:
  container_name: ars0n-framework-v2-client
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
  <img src="assets/footer.png" alt="Footer" width="680">
</p>
