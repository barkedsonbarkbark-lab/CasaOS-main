#!/usr/bin/env bash
set -euo pipefail
cd /opt/casaos-main; git pull --ff-only; git submodule update --init --recursive; chmod +x scripts/generate-code.sh; ./scripts/generate-code.sh; go mod download; go mod tidy; CGO_ENABLED=1 go build -o /opt/casaos-main/casa ./main.go; systemctl restart casaos
