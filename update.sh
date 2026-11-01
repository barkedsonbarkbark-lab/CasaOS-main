#!/usr/bin/env bash
set -Eeuo pipefail
[[ $EUID -eq 0 ]] || { echo "Run with sudo."; exit 1; }
cd /opt/casaos-main
git pull --ff-only
git submodule update --init --recursive
chmod +x scripts/generate-code.sh
./scripts/generate-code.sh
go mod download
CGO_ENABLED=1 go build -o ./casaos ./main.go
systemctl restart casaos
sleep 2
systemctl is-active --quiet casaos || { systemctl status casaos --no-pager -l; journalctl -u casaos -n 100 --no-pager; exit 1; }
echo "CasaOS updated and running."
