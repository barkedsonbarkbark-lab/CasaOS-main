#!/usr/bin/env bash
set -euo pipefail
REPO_URL='https://github.com/barkedsonbarkbark-lab/CasaOS-main.git'; INSTALL_DIR='/opt/casaos-main'
[[ $EUID -eq 0 ]] || { echo 'Run with sudo.'; exit 1; }; . /etc/os-release
case "$ID" in ubuntu|debian) ;; *) echo "Unsupported OS: $ID"; exit 1;; esac
export DEBIAN_FRONTEND=noninteractive
apt-get update; apt-get install -y git curl ca-certificates build-essential pkg-config libsqlite3-dev golang-go
rm -rf "$INSTALL_DIR"; git clone --recurse-submodules "$REPO_URL" "$INSTALL_DIR"; cd "$INSTALL_DIR"; git submodule update --init --recursive
[[ -f api/casaos/openapi.yaml ]] || { echo 'ERROR: api/casaos/openapi.yaml is missing from the repository.'; exit 1; }
chmod +x scripts/generate-code.sh; ./scripts/generate-code.sh
go mod download; go mod tidy; CGO_ENABLED=1 go build -o "$INSTALL_DIR/casa" ./main.go
id -u casaos >/dev/null 2>&1 || useradd --system --home "$INSTALL_DIR" --shell /usr/sbin/nologin casaos
chown -R casaos:casaos "$INSTALL_DIR"
cat >/etc/systemd/system/casaos.service <<UNIT
[Unit]
Description=CasaOS
After=network-online.target docker.service
Wants=network-online.target
[Service]
Type=simple
User=casaos
WorkingDirectory=$INSTALL_DIR
ExecStart=$INSTALL_DIR/casa
Restart=on-failure
RestartSec=5
[Install]
WantedBy=multi-user.target
UNIT
systemctl daemon-reload; systemctl enable --now casaos
echo 'CasaOS installed.'
