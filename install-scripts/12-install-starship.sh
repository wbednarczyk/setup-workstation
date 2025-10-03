#!/usr/bin/env bash
# 12-install-starship.sh
# Installs Starship prompt into /usr/local/bin (idempotent). Works on Ubuntu (incl. WSL).

set -euo pipefail
log(){ printf "\033[1;34m[STARSHIP]\033[0m %s\n" "$*"; }
err(){ printf "\033[1;31m[ERR ]\033[0m %s\n" "$*" >&2; }

if [[ $EUID -ne 0 ]]; then
  log "Re-executing with sudo..."
  exec sudo -E bash "$0" "$@"
fi

apt-get update -y
apt-get install -y --no-install-recommends ca-certificates curl

if command -v starship >/dev/null 2>&1; then
  log "Starship already installed: $(starship --version)"
else
  log "Installing Starship to /usr/local/bin ..."
  curl -fsSL https://starship.rs/install.sh | sh -s -- -y -b /usr/local/bin
fi

# verify
if ! command -v starship >/dev/null 2>&1; then
  err "Starship not found after install."
  exit 1
fi

starship --version
log "Install/upgrade done."
