#!/usr/bin/env bash
set -euo pipefail

REPO="https://github.com/barkedsonbarkbark-lab/CasaOS-main.git"
INSTALL_DIR="/opt/casaos-main"
BIN_PATH="/usr/local/bin/casaos"
CONFIG_DIR="/etc/casaos"
CONFIG_FILE="$CONFIG_DIR/casaos.conf"
SERVICE_FILE="/etc/systemd/system/casaos.service"
DATA_DIR="/var/lib/casaos"
LOG_DIR="/var/log/casaos"
RUNTIME_DIR="/var/run/casaos"

log(){ printf '\n[%s] %s\n' "CasaOS" "$*"; }
die(){ echo "ERROR: $*" >&2; exit 1; }

[[ "$(id -u)" -eq 0 ]] || die "Run as root: curl -fsSL https://raw.githubusercontent.com/barkedsonbarkbark-lab/CasaOS-main/main/install.sh | sudo bash"
[[ -f /etc/os-release ]] || die "Cannot detect Linux distribution."
. /etc/os-release
case "${ID:-}" in
  ubuntu|debian|linuxmint|pop) ;;
  *) die "This installer currently supports Ubuntu/Debian-based systems. Detected: ${ID:-unknown}" ;;
esac

export DEBIAN_FRONTEND=noninteractive
log "Installing build dependencies"
apt-get update
apt-get install -y ca-certificates curl git build-essential pkg-config libsqlite3-dev

if ! command -v go >/dev/null 2>&1; then
  log "Installing Go"
  apt-get install -y golang
fi

go version || die "Go installation failed."

log "Preparing source tree"
if [[ -d "$INSTALL_DIR/.git" ]]; then
  git -C "$INSTALL_DIR" fetch --all --prune
  git -C "$INSTALL_DIR" reset --hard origin/main
  git -C "$INSTALL_DIR" submodule sync --recursive
  git -C "$INSTALL_DIR" submodule update --init --recursive
else
  rm -rf "$INSTALL_DIR"
  git clone --recurse-submodules "$REPO" "$INSTALL_DIR"
fi

cd "$INSTALL_DIR"

[[ -f api/casaos/openapi.yaml ]] || die "api/casaos/openapi.yaml is missing from the repository. Push the file from the provided project ZIP to GitHub."

log "Generating missing Go code"
./scripts/generate-code.sh

log "Building CasaOS backend"
CGO_ENABLED=1 go build -o "$INSTALL_DIR/casaos" ./main.go
install -m 0755 "$INSTALL_DIR/casaos" "$BIN_PATH"

log "Installing configuration and directories"
mkdir -p "$CONFIG_DIR" "$DATA_DIR" "$LOG_DIR" "$RUNTIME_DIR"
if [[ ! -f "$CONFIG_FILE" ]]; then
  install -m 0644 build/sysroot/etc/casaos/casaos.conf.sample "$CONFIG_FILE"
fi

cat > "$SERVICE_FILE" <<UNIT
[Unit]
Description=CasaOS Main Service (custom build)
After=network-online.target
Wants=network-online.target

[Service]
Type=notify
ExecStart=$BIN_PATH -c $CONFIG_FILE
Restart=on-failure
RestartSec=3
WorkingDirectory=$INSTALL_DIR
Environment=HOME=/root

[Install]
WantedBy=multi-user.target
UNIT

systemctl daemon-reload
systemctl enable casaos.service
systemctl restart casaos.service || true

log "Installation completed"
echo "Binary: $BIN_PATH"
echo "Source: $INSTALL_DIR"
echo "Service: systemctl status casaos"
echo "Logs: journalctl -u casaos -f"
echo "NOTE: CasaOS main depends on the CasaOS gateway/message-bus ecosystem for a complete UI deployment."
