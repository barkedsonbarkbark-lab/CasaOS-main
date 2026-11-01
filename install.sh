#!/usr/bin/env bash
set -euo pipefail

REPO_URL="https://github.com/barkedsonbarkbark-lab/CasaOS-main.git"
INSTALL_DIR="/opt/casaos-main"
BIN_PATH="/usr/local/bin/casaos-main"
SERVICE_PATH="/etc/systemd/system/casaos-main.service"
CONFIG_DIR="/etc/casaos"
LOG_DIR="/var/log/casaos"

if [[ $EUID -ne 0 ]]; then
  echo "Run this installer with sudo."
  exit 1
fi

. /etc/os-release
if [[ "${ID:-}" != "ubuntu" && "${ID_LIKE:-}" != *ubuntu* ]]; then
  echo "This installer targets Ubuntu LTS. Detected: ${PRETTY_NAME:-unknown}"
  exit 1
fi

export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y git curl ca-certificates build-essential pkg-config libsqlite3-dev golang-go

rm -rf "$INSTALL_DIR"
git clone --recurse-submodules "$REPO_URL" "$INSTALL_DIR"
cd "$INSTALL_DIR"
git submodule update --init --recursive

if [[ ! -d UI && -d CasaOS-UI ]]; then
  ln -s CasaOS-UI UI
fi

# Build the backend. The upstream Makefile may require UPX; avoid that optional step.
CGO_ENABLED=1 go build -o casa main.go
install -Dm755 casa "$BIN_PATH"

mkdir -p "$CONFIG_DIR" "$LOG_DIR"
if [[ -f build/sysroot/etc/casaos/casaos.conf.sample && ! -f "$CONFIG_DIR/casaos.conf" ]]; then
  install -m644 build/sysroot/etc/casaos/casaos.conf.sample "$CONFIG_DIR/casaos.conf"
fi

cat > "$SERVICE_PATH" <<SERVICE
[Unit]
Description=CasaOS Main Service (GitHub build)
After=network-online.target docker.service
Wants=network-online.target

[Service]
Type=simple
ExecStart=$BIN_PATH
Restart=on-failure
RestartSec=3
Environment=HOME=/root

[Install]
WantedBy=multi-user.target
SERVICE

systemctl daemon-reload
systemctl enable --now casaos-main.service

echo
echo "CasaOS main component installed."
echo "Service: systemctl status casaos-main"
echo "Logs:    journalctl -u casaos-main -f"
echo "Source:  $INSTALL_DIR"
echo
echo "NOTE: This repository is the CasaOS main component; a complete CasaOS deployment also requires its companion services/UI."
