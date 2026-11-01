#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

command -v go >/dev/null 2>&1 || { echo "ERROR: Go is required." >&2; exit 1; }

if [[ ! -f api/casaos/openapi.yaml ]]; then
  echo "ERROR: api/casaos/openapi.yaml is missing." >&2
  echo "The CasaOS API specification must be present before code generation." >&2
  exit 1
fi

mkdir -p codegen codegen/message_bus

echo "[1/2] Generating CasaOS API code..."
go run github.com/deepmap/oapi-codegen/cmd/oapi-codegen@v1.12.4 \
  -generate types,server,spec \
  -package codegen \
  api/casaos/openapi.yaml > codegen/casaos_api.go

echo "[2/2] Generating Message Bus API code..."
go run github.com/deepmap/oapi-codegen/cmd/oapi-codegen@v1.12.4 \
  -generate types,client \
  -package message_bus \
  https://raw.githubusercontent.com/IceWhaleTech/CasaOS-MessageBus/main/api/message_bus/openapi.yaml > codegen/message_bus/api.go

test -s codegen/casaos_api.go
test -s codegen/message_bus/api.go

echo "Code generation complete."
