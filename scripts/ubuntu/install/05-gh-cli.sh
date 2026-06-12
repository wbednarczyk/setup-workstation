#!/usr/bin/env bash
# 05-gh-cli.sh
# Installs GitHub CLI from GitHub's official apt repository. Safe to re-run.

set -euo pipefail

log(){ printf "\033[1;34m[GH]\033[0m %s\n" "$*"; }
err(){ printf "\033[1;31m[ERR ]\033[0m %s\n" "$*" >&2; }

if [[ $EUID -ne 0 ]]; then
  log "Re-executing with sudo..."
  exec sudo -E bash "$0" "$@"
fi

export DEBIAN_FRONTEND=noninteractive

apt-get update -y
apt-get install -y --no-install-recommends ca-certificates curl gnupg

install -m 0755 -d /etc/apt/keyrings
if [[ ! -f /etc/apt/keyrings/githubcli-archive-keyring.gpg ]]; then
  log "Installing GitHub CLI apt keyring..."
  curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
    -o /etc/apt/keyrings/githubcli-archive-keyring.gpg
  chmod a+r /etc/apt/keyrings/githubcli-archive-keyring.gpg
else
  log "GitHub CLI apt keyring already present."
fi

install -m 0755 -d /etc/apt/sources.list.d
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
  > /etc/apt/sources.list.d/github-cli.list

apt-get update -y
apt-get install -y --no-install-recommends gh

if ! command -v gh >/dev/null 2>&1; then
  err "gh not found after install."
  exit 1
fi

gh --version
log "Install/upgrade done."
