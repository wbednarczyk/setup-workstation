#!/usr/bin/env bash
# 07-nix-direnv.sh
# Enables direnv in Bash and configures Nix for `nix develop`.

set -euo pipefail

log(){ printf "\033[1;34m[NIX-DIRENV]\033[0m %s\n" "$*"; }
err(){ printf "\033[1;31m[ERR ]\033[0m %s\n" "$*" >&2; }

TARGET_USER="${SUDO_USER:-$USER}"
HOME_DIR="$(eval echo "~$TARGET_USER")"
DROPIN_DIR="$HOME_DIR/.bashrc.d"
DROPIN_FILE="$DROPIN_DIR/99-direnv.sh"
NIX_CONFIG_DIR="$HOME_DIR/.config/nix"
NIX_CONFIG_FILE="$NIX_CONFIG_DIR/nix.conf"

[[ -d "$HOME_DIR" ]] || { err "Home dir not found: $HOME_DIR"; exit 1; }

if ! command -v direnv >/dev/null 2>&1; then
  err "direnv not found. Install base packages first (10-install-base-packages.sh)."
  exit 1
fi

mkdir -p "$DROPIN_DIR" "$NIX_CONFIG_DIR"

cat >"$DROPIN_FILE" <<'EOF'
# ~/.bashrc.d/99-direnv.sh
# Enable direnv for interactive Bash shells.
case $- in *i*) ;; *) return 0 2>/dev/null || exit 0 ;; esac

eval "$(direnv hook bash)"
EOF

if [[ -f "$NIX_CONFIG_FILE" ]] && grep -qE '^[[:space:]]*experimental-features[[:space:]]*=' "$NIX_CONFIG_FILE"; then
  log "Nix experimental-features already configured in $NIX_CONFIG_FILE"
else
  {
    [[ -s "$NIX_CONFIG_FILE" ]] && printf "\n"
    printf "experimental-features = nix-command flakes\n"
  } >>"$NIX_CONFIG_FILE"
  log "Enabled nix-command and flakes in $NIX_CONFIG_FILE"
fi

chown -R "$TARGET_USER:$TARGET_USER" "$DROPIN_DIR" "$NIX_CONFIG_DIR"
chmod 0755 "$DROPIN_DIR" "$NIX_CONFIG_DIR"
chmod 0644 "$DROPIN_FILE" "$NIX_CONFIG_FILE"

log "direnv drop-in written: $DROPIN_FILE"
echo "Reload your shell:  source ~/.bashrc"
echo "In a project with .envrc, run:  direnv allow"
