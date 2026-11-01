#!/usr/bin/env bash
set -Eeuo pipefail
[[ $EUID -eq 0 ]] || { echo 'Run with sudo.' >&2; exit 1; }
systemctl disable --now casaos-main.service 2>/dev/null || true
rm -f /etc/systemd/system/casaos-main.service /usr/local/bin/casaos-main-status /usr/local/bin/casaos-main-update
systemctl daemon-reload
rm -rf /opt/casaos-main
rm -rf /etc/casaos-main /var/log/casaos-main
printf '%s\n' 'CasaOS-main development installation removed. Docker and existing Docker data were NOT removed.'
