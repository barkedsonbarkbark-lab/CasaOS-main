#!/usr/bin/env bash
set -euo pipefail
ROOT="/opt/casaos-main"
cd "$ROOT"
git pull --ff-only
git submodule update --init --recursive
[[ -f api/casaos/openapi.yaml ]] || { echo 'ERROR: api/casaos/openapi.yaml missing'; exit 1; }
./scripts/generate-code.sh
go mod download
go mod tidy
CGO_ENABLED=1 go build -o casa main.go
install -m 0755 casa /usr/local/bin/casaos-main
systemctl restart casaos-main
echo 'Update complete.'
