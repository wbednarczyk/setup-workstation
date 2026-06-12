#!/usr/bin/env bash
# 13-install-nix.sh
# Installs Nix using the official installer. Safe to re-run.

set -euo pipefail

log(){ printf "\033[1;34m[NIX]\033[0m %s\n" "$*"; }
err(){ printf "\033[1;31m[ERR ]\033[0m %s\n" "$*" >&2; }

ensure_bash_dropin() {
  local target_user="${SUDO_USER:-$USER}"
  local home_dir
  home_dir="$(eval echo "~$target_user")"
  local dropin_dir="$home_dir/.bashrc.d"
  local dropin_file="$dropin_dir/10-nix.sh"

  mkdir -p "$dropin_dir"
  cat >"$dropin_file" <<'EOF'
# ~/.bashrc.d/10-nix.sh
# Load Nix for interactive Bash shells, including VS Code terminals.
case $- in *i*) ;; *) return 0 2>/dev/null || exit 0 ;; esac

if [ -e /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]; then
  if ! command -v nix >/dev/null 2>&1; then
    unset __ETC_PROFILE_NIX_SOURCED
  fi
  . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
fi
EOF

  chown "$target_user:$target_user" "$dropin_dir" "$dropin_file"
  chmod 0755 "$dropin_dir"
  chmod 0644 "$dropin_file"
  log "Bash drop-in written: $dropin_file"
}

if [[ $EUID -eq 0 ]]; then
  err "Run this script as your normal user, not root. The Nix installer will ask for sudo if needed."
  exit 1
fi

if command -v nix >/dev/null 2>&1; then
  log "Nix already installed: $(nix --version)"
  ensure_bash_dropin
  exit 0
fi

INSTALLER="$(mktemp)"
cleanup() {
  rm -f "$INSTALLER"
}
trap cleanup EXIT

log "Downloading official Nix installer..."
curl -fsSL https://nixos.org/nix/install -o "$INSTALLER"

log "Installing Nix in multi-user daemon mode..."
sh "$INSTALLER" --daemon --yes
ensure_bash_dropin

cat <<'EOF'
===============================================================
Nix installation finished.

Open a new terminal, or load Nix into the current shell with:
  . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh

Then run:
  nix --version
===============================================================
EOF
