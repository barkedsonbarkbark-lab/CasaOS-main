#!/usr/bin/env bash
set -Eeuo pipefail

REPO_URL="https://github.com/barkedsonbarkbark-lab/CasaOS-main.git"
INSTALL_DIR="/opt/casaos-main"
CONFIG_DIR="/etc/casaos"
CONFIG_FILE="$CONFIG_DIR/casaos.conf"
DATA_DIR="/var/lib/casaos"
LOG_DIR="/var/log/casaos"
SHELL_DIR="/usr/share/casaos/shell"
RUNTIME_DIR="/var/run/casaos"
SERVICE_FILE="/etc/systemd/system/casaos.service"
LOG_FILE="/var/log/casaos-install.log"

exec > >(tee -a "$LOG_FILE") 2>&1
trap 'echo "ERROR: installer failed at line $LINENO. See $LOG_FILE and: journalctl -u casaos -n 100 --no-pager" >&2' ERR

[[ $EUID -eq 0 ]] || { echo "Run with sudo."; exit 1; }
. /etc/os-release
case "${ID:-}" in ubuntu|debian) ;; *) echo "Unsupported OS: ${ID:-unknown}"; exit 1;; esac

export DEBIAN_FRONTEND=noninteractive
echo "==> Installing build dependencies"
apt-get update
apt-get install -y git curl ca-certificates build-essential pkg-config libsqlite3-dev golang-go

command -v go >/dev/null || { echo "ERROR: Go is not installed."; exit 1; }

echo "==> Cloning CasaOS source"
rm -rf "$INSTALL_DIR"
git clone --recurse-submodules "$REPO_URL" "$INSTALL_DIR"
cd "$INSTALL_DIR"
git submodule update --init --recursive

[[ -f api/casaos/openapi.yaml ]] || { echo "ERROR: api/casaos/openapi.yaml is missing from the repository."; exit 1; }
[[ -f build/sysroot/etc/casaos/casaos.conf.sample ]] || { echo "ERROR: CasaOS config sample is missing."; exit 1; }

chmod +x scripts/generate-code.sh

echo "==> Downloading Go modules"
go mod download

echo "==> Generating CasaOS and MessageBus code"
./scripts/generate-code.sh

echo "==> Building CasaOS"
CGO_ENABLED=1 go build -o "$INSTALL_DIR/casaos" ./main.go
chmod 0755 "$INSTALL_DIR/casaos"

id -u casaos >/dev/null 2>&1 || useradd --system --home "$INSTALL_DIR" --shell /usr/sbin/nologin casaos

echo "==> Creating runtime directories and configuration"
install -d -o root -g root -m 0755 "$CONFIG_DIR"
install -d -o casaos -g casaos -m 0755 "$DATA_DIR" "$DATA_DIR/conf" "$LOG_DIR" "$SHELL_DIR" "$RUNTIME_DIR"
# CasaOS's InitSetup creates this file when absent. Create it ahead of time so the
# unprivileged systemd service never needs write access to /etc.
install -o root -g casaos -m 0640 build/sysroot/etc/casaos/casaos.conf.sample "$CONFIG_FILE"

# Preserve ownership/permissions expected by the application.
chown -R casaos:casaos "$DATA_DIR" "$LOG_DIR" "$SHELL_DIR" "$RUNTIME_DIR"
chown -R root:root "$INSTALL_DIR"
chmod 0755 "$INSTALL_DIR" "$INSTALL_DIR/casaos"

cat > "$SERVICE_FILE" <<UNIT
[Unit]
Description=CasaOS
After=network-online.target docker.service
Wants=network-online.target

[Service]
Type=simple
User=casaos
Group=casaos
WorkingDirectory=$INSTALL_DIR
ExecStart=$INSTALL_DIR/casaos -c $CONFIG_FILE
Restart=on-failure
RestartSec=5
Environment=HOME=$INSTALL_DIR

[Install]
WantedBy=multi-user.target
UNIT

systemctl daemon-reload
systemctl enable casaos
systemctl restart casaos || systemctl start casaos
sleep 2

if ! systemctl is-active --quiet casaos; then
  echo "ERROR: CasaOS did not stay running."
  systemctl status casaos --no-pager -l || true
  journalctl -u casaos -n 100 --no-pager || true
  exit 1
fi

echo ""
echo "CasaOS is installed and running."
echo "Service: systemctl status casaos"
echo "Logs:    journalctl -u casaos -f"
echo "Config:  $CONFIG_FILE"
echo "Install log: $LOG_FILE"
