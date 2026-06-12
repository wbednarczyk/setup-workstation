#!/usr/bin/env bash
# 06-radicle.sh
# Installs the Radicle toolchain from Radicle's official apt repository. Safe to re-run.

set -euo pipefail

log(){ printf "\033[1;34m[RADICLE]\033[0m %s\n" "$*"; }
err(){ printf "\033[1;31m[ERR ]\033[0m %s\n" "$*" >&2; }

if [[ $EUID -ne 0 ]]; then
  log "Re-executing with sudo..."
  exec sudo -E bash "$0" "$@"
fi

export DEBIAN_FRONTEND=noninteractive

apt-get update -y
apt-get install -y --no-install-recommends ca-certificates curl

TMP_DIR="$(mktemp -d)"
cleanup() {
  rm -rf "$TMP_DIR"
}
trap cleanup EXIT

if [[ ! -f /usr/share/radicle/radicle-archive-keyring.asc ]]; then
  log "Installing Radicle apt keyring..."
  curl -fsSL -o "$TMP_DIR/radicle-archive-keyring.deb" \
    https://radicle.dev/apt/radicle-archive-keyring.deb
  chmod a+r "$TMP_DIR/radicle-archive-keyring.deb"
  apt-get install -y --no-install-recommends "$TMP_DIR/radicle-archive-keyring.deb"
else
  log "Radicle apt keyring already present."
fi

install -m 0755 -d /etc/apt/sources.list.d
cat > /etc/apt/sources.list.d/radicle.list <<'EOF'
deb [signed-by=/usr/share/radicle/radicle-archive-keyring.asc] https://radicle.dev/apt release main
EOF

apt-get update -y
apt-get install -y --no-install-recommends radicle

if ! command -v rad >/dev/null 2>&1; then
  err "rad not found after install."
  exit 1
fi

rad --version
log "Install/upgrade done."
