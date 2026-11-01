#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
mkdir -p codegen codegen/message_bus

go run github.com/deepmap/oapi-codegen/cmd/oapi-codegen@v1.12.4 \
  -generate types,server,spec \
  -package codegen \
  ../api/casaos/openapi.yaml > codegen/casaos_api.go

go run github.com/deepmap/oapi-codegen/cmd/oapi-codegen@v1.12.4 \
  -generate types,client \
  -package message_bus \
  https://raw.githubusercontent.com/IceWhaleTech/CasaOS-MessageBus/main/api/message_bus/openapi.yaml > codegen/message_bus/api.go

echo "Code generation completed."
