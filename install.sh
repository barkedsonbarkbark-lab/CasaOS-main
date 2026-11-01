#!/usr/bin/env bash
set -Eeuo pipefail

REPO="${CASAOS_REPO:-https://github.com/barkedsonbarkbark-lab/CasaOS-main.git}"
BRANCH="${CASAOS_BRANCH:-main}"
PREFIX="${CASAOS_PREFIX:-/opt/casaos-main}"
DATA="${CASAOS_DATA:-/var/lib/casaos-main}"
SERVICE="casaos-main.service"
SRC="$PREFIX/source"
BIN="$PREFIX/bin/casaos-main"

log(){ printf '\n\033[1;36m[CasaOS-ZimaOS]\033[0m %s\n' "$*"; }
die(){ echo "ERROR: $*" >&2; exit 1; }
trap 'die "Installation failed at line $LINENO."' ERR

[[ $EUID -eq 0 ]] || die "Run with sudo."
[[ -r /etc/os-release ]] || die "Cannot detect Linux distribution."
. /etc/os-release
[[ "$ID" == ubuntu || "$ID_LIKE" == *debian* ]] || die "Ubuntu/Debian is required."

log "Installing build/runtime dependencies"
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y git curl ca-certificates build-essential pkg-config libsqlite3-dev smartmontools parted ntfs-3g net-tools samba cifs-utils udevil golang-go nodejs npm

if ! command -v yarn >/dev/null 2>&1; then
  npm install -g yarn
fi

if ! command -v docker >/dev/null 2>&1; then
  log "Installing Docker from Ubuntu packages"
  apt-get install -y docker.io docker-compose-v2
fi
systemctl enable --now docker

log "Preparing source tree"
mkdir -p "$PREFIX" "$DATA"
if [[ -d "$SRC/.git" ]]; then
  git -C "$SRC" fetch --all --prune
  git -C "$SRC" checkout "$BRANCH"
  git -C "$SRC" pull --ff-only origin "$BRANCH"
else
  rm -rf "$SRC"
  git clone --branch "$BRANCH" --recurse-submodules "$REPO" "$SRC"
fi

git -C "$SRC" submodule update --init --recursive || true

# The repository's Makefile references CasaOS-UI; the historical source stores it as a submodule.
if [[ ! -d "$SRC/CasaOS-UI" ]]; then
  git -C "$SRC" clone --depth 1 https://github.com/IceWhaleTech/CasaOS-UI.git "$SRC/CasaOS-UI"
fi

log "Building CasaOS backend"
cd "$SRC"
export CGO_ENABLED=1
go build -o "$BIN" ./main.go
chmod 0755 "$BIN"

# Install the repository's helper files without overwriting unrelated system files.
mkdir -p /etc/casaos-main /var/log/casaos-main
if [[ -f "$SRC/build/sysroot/etc/casaos/casaos.conf.sample" ]]; then
  cp -n "$SRC/build/sysroot/etc/casaos/casaos.conf.sample" /etc/casaos-main/casaos.conf || true
fi

cat > /etc/systemd/system/$SERVICE <<UNIT
[Unit]
Description=CasaOS Main (barkedsonbarkbark-lab build)
After=network-online.target docker.service
Wants=network-online.target
Requires=docker.service

[Service]
Type=simple
User=root
WorkingDirectory=$SRC
ExecStart=$BIN
Restart=on-failure
RestartSec=3
LimitNOFILE=1048576
Environment=HOME=/root

[Install]
WantedBy=multi-user.target
UNIT

systemctl daemon-reload
systemctl enable --now "$SERVICE"
sleep 2

if systemctl is-active --quiet "$SERVICE"; then
  log "Backend service is running."
else
  journalctl -u "$SERVICE" -n 80 --no-pager || true
  die "Backend service did not start."
fi

cat > /usr/local/bin/casaos-main-status <<'STATUS'
#!/usr/bin/env bash
systemctl --no-pager status casaos-main.service
STATUS
chmod +x /usr/local/bin/casaos-main-status

cat > /usr/local/bin/casaos-main-update <<'UPDATE'
#!/usr/bin/env bash
set -euo pipefail
exec /opt/casaos-main/source/update.sh
UPDATE
chmod +x /usr/local/bin/casaos-main-update

log "Installation complete."
echo "Source: $SRC"
echo "Service: $SERVICE"
echo "Status: systemctl status $SERVICE"
echo "Logs:   journalctl -u $SERVICE -f"
