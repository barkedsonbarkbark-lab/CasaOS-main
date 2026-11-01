#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"; cd "$ROOT_DIR"
OAPI='github.com/deepmap/oapi-codegen/cmd/oapi-codegen@v1.12.4'
SPEC='api/casaos/openapi.yaml'
MB='https://raw.githubusercontent.com/IceWhaleTech/CasaOS-MessageBus/main/api/message_bus/openapi.yaml'
command -v go >/dev/null || { echo 'ERROR: Go is required.' >&2; exit 1; }
[[ -f "$SPEC" ]] || { echo "ERROR: $SPEC is missing from the repository." >&2; exit 1; }
mkdir -p codegen/message_bus
echo 'Generating CasaOS API...'; go run "$OAPI" -generate types,server,spec -package codegen "$SPEC" > codegen/casaos_api.go
echo 'Generating MessageBus API...'; tmp="$(mktemp)"; trap 'rm -f "$tmp"' EXIT
go run "$OAPI" -generate types,client -package message_bus "$MB" > "$tmp"; mv "$tmp" codegen/message_bus/api.go
echo 'Code generation complete.'
