#!/usr/bin/env bash
# 00-base-packages.sh
# Install base packages on Ubuntu (incl. bash-completion). Safe to re-run.

set -euo pipefail

log(){ printf "\033[1;34m[BASE]\033[0m %s\n" "$*"; }
err(){ printf "\033[1;31m[ERR ]\033[0m %s\n" "$*" >&2; }

if [[ $EUID -ne 0 ]]; then
  log "Re-executing with sudo..."
  exec sudo -E bash "$0" "$@"
fi

export DEBIAN_FRONTEND=noninteractive

log "apt-get update…"
apt-get update -y

PKGS=(
  # essentials
  ca-certificates curl wget gnupg lsb-release apt-transport-https
  build-essential make pkg-config

  # shell & UX
  bash-completion htop tmux tree less vim

  # archives
  unzip zip tar xz-utils

  # CLI helpers
  jq yq fzf ripgrep

  # env helpers
  direnv

  # networking/tools
  net-tools iproute2 dnsutils
)

log "Installing base packages…"
apt-get install -y --no-install-recommends "${PKGS[@]}"

log "Cleaning apt cache…"
apt-get autoremove -y >/dev/null 2>&1 || true
apt-get clean

log "Done"
