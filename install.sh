#!/usr/bin/env bash
set -euo pipefail

REPO_URL="https://github.com/barkedsonbarkbark-lab/CasaOS-main.git"
INSTALL_DIR="/opt/casaos-main"
CONFIG_DIR="/etc/casaos"
DATA_DIR="/var/lib/casaos"
LOG_DIR="/var/log/casaos"
SERVICE="casaos"

if [[ $EUID -ne 0 ]]; then echo "Run with sudo." >&2; exit 1; fi
if [[ ! -f /etc/os-release ]]; then echo "Unsupported OS." >&2; exit 1; fi
. /etc/os-release

export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y git curl build-essential ca-certificates pkg-config libsqlite3-dev

# Install Go if it is missing. Prefer the distro package on Ubuntu/Debian.
if ! command -v go >/dev/null 2>&1; then
  apt-get install -y golang
fi

mkdir -p "$CONFIG_DIR" "$DATA_DIR" "$LOG_DIR" "$DATA_DIR/conf" /usr/share/casaos/shell

if [[ -d "$INSTALL_DIR/.git" ]]; then
  git -C "$INSTALL_DIR" fetch --depth=1 origin main
  git -C "$INSTALL_DIR" reset --hard origin/main
else
  rm -rf "$INSTALL_DIR"
  git clone --depth=1 "$REPO_URL" "$INSTALL_DIR"
fi

cd "$INSTALL_DIR"
[[ -f api/casaos/openapi.yaml ]] || { echo "ERROR: api/casaos/openapi.yaml is missing from repository." >&2; exit 1; }
[[ -f build/sysroot/etc/casaos/casaos.conf.sample ]] || { echo "ERROR: config sample missing." >&2; exit 1; }

# The binary's init path creates the file but cannot create /etc/casaos itself.
install -m 0644 build/sysroot/etc/casaos/casaos.conf.sample "$CONFIG_DIR/casaos.conf.sample"
if [[ ! -f "$CONFIG_DIR/casaos.conf" ]]; then
  install -m 0644 build/sysroot/etc/casaos/casaos.conf.sample "$CONFIG_DIR/casaos.conf"
fi

./scripts/generate-code.sh
go mod tidy
go build -trimpath -o "$INSTALL_DIR/casaos" ./main.go
install -m 0755 "$INSTALL_DIR/casaos" /usr/local/bin/casaos

cat > /etc/systemd/system/casaos.service <<UNIT
[Unit]
Description=CasaOS Main Service
After=network-online.target
Wants=network-online.target

[Service]
Type=notify
ExecStart=/usr/local/bin/casaos -c /etc/casaos/casaos.conf
WorkingDirectory=$INSTALL_DIR
Restart=on-failure
RestartSec=3
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
UNIT

systemctl daemon-reload
systemctl enable --now "$SERVICE"
sleep 2
if ! systemctl is-active --quiet "$SERVICE"; then
  echo "CasaOS failed to start. Logs:" >&2
  journalctl -u "$SERVICE" -n 80 --no-pager >&2 || true
  exit 1
fi

echo "CasaOS installed and started successfully."
systemctl --no-pager --full status "$SERVICE" || true
