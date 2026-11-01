#!/usr/bin/env bash
set -Eeuo pipefail
[[ $EUID -eq 0 ]] || { echo "Run with sudo."; exit 1; }
systemctl disable --now casaos 2>/dev/null || true
rm -f /etc/systemd/system/casaos.service
systemctl daemon-reload
rm -rf /opt/casaos-main
userdel casaos 2>/dev/null || true
echo "CasaOS service and installation removed. Data/config were preserved under /etc/casaos and /var/lib/casaos."
