#!/usr/bin/env bash
set -euo pipefail

REPO="https://github.com/barkedsonbarkbark-lab/CasaOS-main.git"
INSTALL_DIR="/opt/casaos-main"
SERVICE_NAME="casaos-main"
SERVICE_FILE="/etc/systemd/system/${SERVICE_NAME}.service"

if [[ $EUID -ne 0 ]]; then echo "Run with sudo: curl -fsSL ... | sudo bash"; exit 1; fi
source /etc/os-release
case "${ID:-}" in ubuntu|debian) ;; *) echo "This installer supports Ubuntu/Debian."; exit 1;; esac

export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y git curl ca-certificates build-essential pkg-config golang-go

if ! command -v go >/dev/null 2>&1; then echo "Go installation failed."; exit 1; fi

rm -rf "$INSTALL_DIR"
git clone --recurse-submodules "$REPO" "$INSTALL_DIR"
cd "$INSTALL_DIR"

git submodule update --init --recursive

if [[ ! -f api/casaos/openapi.yaml ]]; then
  echo "ERROR: api/casaos/openapi.yaml is missing from the checkout."
  exit 1
fi

chmod +x scripts/generate-code.sh
./scripts/generate-code.sh

go mod download
go mod tidy
CGO_ENABLED=1 go build -o casa main.go
install -m 0755 casa /usr/local/bin/casaos-main

mkdir -p /etc/casaos /var/lib/casaos

cat > "$SERVICE_FILE" <<UNIT
[Unit]
Description=CasaOS Main Backend
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
WorkingDirectory=$INSTALL_DIR
ExecStart=/usr/local/bin/casaos-main
Restart=on-failure
RestartSec=3
Environment=CASAOS_CONFIG_PATH=/etc/casaos

[Install]
WantedBy=multi-user.target
UNIT

systemctl daemon-reload
systemctl enable --now "$SERVICE_NAME"

echo
echo "CasaOS Main installed."
echo "Service: systemctl status $SERVICE_NAME"
echo "Logs:    journalctl -u $SERVICE_NAME -f"
