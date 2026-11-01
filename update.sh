#!/usr/bin/env bash
set -euo pipefail
INSTALL_DIR="/opt/casaos-main"
[[ "$(id -u)" -eq 0 ]] || { echo "Run as root." >&2; exit 1; }
[[ -d "$INSTALL_DIR/.git" ]] || { echo "CasaOS is not installed at $INSTALL_DIR." >&2; exit 1; }
cd "$INSTALL_DIR"
git fetch --all --prune
git reset --hard origin/main
git submodule sync --recursive
git submodule update --init --recursive
./scripts/generate-code.sh
CGO_ENABLED=1 go build -o casaos ./main.go
install -m 0755 casaos /usr/local/bin/casaos
systemctl daemon-reload
systemctl restart casaos.service
echo "CasaOS updated successfully."
