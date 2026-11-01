#!/usr/bin/env bash
set -Eeuo pipefail
[[ $EUID -eq 0 ]] || { echo 'Run with sudo.' >&2; exit 1; }
SRC=/opt/casaos-main/source
BIN=/opt/casaos-main/bin/casaos-main
[[ -d "$SRC/.git" ]] || { echo "Source not found: $SRC" >&2; exit 1; }
git -C "$SRC" fetch --all --prune
git -C "$SRC" checkout main
git -C "$SRC" pull --ff-only origin main
git -C "$SRC" submodule update --init --recursive || true
cd "$SRC"
CGO_ENABLED=1 go build -o "$BIN" ./main.go
chmod 0755 "$BIN"
systemctl restart casaos-main.service
systemctl --no-pager --full status casaos-main.service
