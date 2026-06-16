#!/usr/bin/env bash
# 10-node.sh
# Installs nvm + Node.js 22 (LTS) for the current user and loads nvm for
# interactive Bash shells via a ~/.bashrc.d drop-in. Safe to re-run.
#
# Node is installed per-user via nvm (not apt) so the version is explicit and
# upgradable without touching system packages. Any distro `nodejs` (often an
# older Node pulled in transitively by other apt packages) is left in place but
# shadowed on PATH by nvm's default alias for interactive shells.

set -euo pipefail

log(){ printf "\033[1;34m[NODE]\033[0m %s\n" "$*"; }
err(){ printf "\033[1;31m[ERR ]\033[0m %s\n" "$*" >&2; }

NVM_VERSION="v0.40.3"
NODE_MAJOR="22"

if [[ $EUID -eq 0 ]]; then
  err "Run this script as your normal user, not root. nvm installs into your home directory."
  exit 1
fi

export NVM_DIR="$HOME/.nvm"

ensure_bash_dropin() {
  local dropin_dir="$HOME/.bashrc.d"
  local dropin_file="$dropin_dir/15-nvm.sh"

  mkdir -p "$dropin_dir"
  cat >"$dropin_file" <<'EOF'
# ~/.bashrc.d/15-nvm.sh
# Load nvm (Node Version Manager) for interactive Bash shells, including VS Code
# terminals. nvm puts the default-alias Node on PATH.
case $- in *i*) ;; *) return 0 2>/dev/null || exit 0 ;; esac

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
EOF

  chmod 0755 "$dropin_dir"
  chmod 0644 "$dropin_file"
  log "Bash drop-in written: $dropin_file"
}

# Install nvm if missing. PROFILE=/dev/null stops the installer from editing
# ~/.bashrc; shell loading is owned by the ~/.bashrc.d drop-in above.
if [[ -s "$NVM_DIR/nvm.sh" ]]; then
  log "nvm already installed at $NVM_DIR"
else
  log "Installing nvm $NVM_VERSION ..."
  curl -fsSL "https://raw.githubusercontent.com/nvm-sh/nvm/${NVM_VERSION}/install.sh" | PROFILE=/dev/null bash
fi

# Load nvm into this non-interactive shell so we can install Node.
# shellcheck disable=SC1091
. "$NVM_DIR/nvm.sh"

log "Installing Node.js ${NODE_MAJOR} (latest LTS in that line) ..."
nvm install "$NODE_MAJOR"
nvm alias default "$NODE_MAJOR"
nvm use default >/dev/null

ensure_bash_dropin

# verify
if ! command -v node >/dev/null 2>&1; then
  err "node not found after install."
  exit 1
fi

log "Node:  $(node --version)"
log "npm:   $(npm --version)"
log "Install/upgrade done. Open a new terminal (or 'source ~/.bashrc') to pick up nvm."
