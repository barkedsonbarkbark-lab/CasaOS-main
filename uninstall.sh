#!/usr/bin/env bash
set -euo pipefail
if [[ $EUID -ne 0 ]]; then echo 'Run as root.'; exit 1; fi
systemctl disable --now casaos-main 2>/dev/null || true
rm -f /etc/systemd/system/casaos-main.service /usr/local/bin/casaos-main
systemctl daemon-reload
rm -rf /opt/casaos-main
# Configuration/data are intentionally preserved.
echo 'CasaOS Main removed. /etc/casaos and /var/lib/casaos were preserved.'
