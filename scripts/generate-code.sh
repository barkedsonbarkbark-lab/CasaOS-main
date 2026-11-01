#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
command -v go >/dev/null 2>&1 || { echo "go is required" >&2; exit 1; }
mkdir -p codegen codegen/message_bus
# Generate the CasaOS API locally from the repository's OpenAPI document.
go run github.com/deepmap/oapi-codegen/cmd/oapi-codegen@v1.12.4 \
  -generate types,server,spec -package codegen \
  api/casaos/openapi.yaml > codegen/casaos_api.go
# Generate the MessageBus client from the upstream MessageBus OpenAPI document.
go run github.com/deepmap/oapi-codegen/cmd/oapi-codegen@v1.12.4 \
  -generate types,client -package message_bus \
  https://raw.githubusercontent.com/IceWhaleTech/CasaOS-MessageBus/main/api/message_bus/openapi.yaml \
  > codegen/message_bus/api.go

echo "Code generation complete."
