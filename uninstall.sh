#!/usr/bin/env bash
set -euo pipefail
[[ "$(id -u)" -eq 0 ]] || { echo "Run as root." >&2; exit 1; }
systemctl disable --now casaos.service 2>/dev/null || true
rm -f /etc/systemd/system/casaos.service /usr/local/bin/casaos
systemctl daemon-reload
rm -rf /opt/casaos-main
printf '%s\n' "CasaOS main service removed. /var/lib/casaos, /var/log/casaos and /etc/casaos were preserved."
