#!/usr/bin/env bash
set -euo pipefail
if [[ $EUID -ne 0 ]]; then echo "Run with sudo."; exit 1; fi
systemctl disable --now casaos-main.service 2>/dev/null || true
rm -f /etc/systemd/system/casaos-main.service /usr/local/bin/casaos-main
systemctl daemon-reload
rm -rf /opt/casaos-main
rm -rf /var/log/casaos
# Configuration under /etc/casaos is intentionally preserved.
echo "CasaOS main component removed. /etc/casaos was preserved."
