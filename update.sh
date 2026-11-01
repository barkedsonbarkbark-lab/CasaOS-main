#!/usr/bin/env bash
set -euo pipefail
if [[ $EUID -ne 0 ]]; then echo "Run with sudo."; exit 1; fi
cd /opt/casaos-main
git fetch --all --prune
git pull --ff-only
git submodule update --init --recursive
CGO_ENABLED=1 go build -o casa main.go
install -Dm755 casa /usr/local/bin/casaos-main
systemctl restart casaos-main
systemctl --no-pager --full status casaos-main || true
