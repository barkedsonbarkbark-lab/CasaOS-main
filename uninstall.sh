#!/usr/bin/env bash
set -euo pipefail
if [[ $EUID -ne 0 ]]; then echo "Run with sudo." >&2; exit 1; fi
systemctl disable --now casaos 2>/dev/null || true
rm -f /etc/systemd/system/casaos.service /usr/local/bin/casaos
systemctl daemon-reload
rm -rf /opt/casaos-main
# Keep /etc/casaos and /var/lib/casaos by default so user configuration/data are not destroyed.
echo "CasaOS service and installed binary removed. Configuration/data were preserved."
