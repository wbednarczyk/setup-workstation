#!/usr/bin/env bash
# 05-editor.sh
# Creates ~/.bashrc.d/00-editor.sh to set vim as default editor.

set -euo pipefail

log(){ printf "\033[1;34m[EDITOR]\033[0m %s\n" "$*"; }
err(){ printf "\033[1;31m[ERR ]\033[0m %s\n" "$*" >&2; }

TARGET_USER="${SUDO_USER:-$USER}"
HOME_DIR="$(eval echo "~$TARGET_USER")"
DROPIN_DIR="$HOME_DIR/.bashrc.d"
FILE="$DROPIN_DIR/00-editor.sh"

[[ -d "$HOME_DIR" ]] || { err "Home dir not found: $HOME_DIR"; exit 1; }
mkdir -p "$DROPIN_DIR"

cat >"$FILE" <<'EOF'
# ~/.bashrc.d/00-editor.sh
# Set vim as default editor for shells and programs.

export EDITOR=vim
export VISUAL=vim
export PAGER=less
EOF

chown "$TARGET_USER:$TARGET_USER" "$FILE"
chmod 0644 "$FILE"

log "Drop-in created: $FILE"
echo "Reload to apply:  source ~/.bashrc"
