#!/usr/bin/env bash
# 05_setup_bashrc_d.sh
# Creates ~/.bashrc.d and ensures ~/.bashrc sources ~/.bashrc.d/*.sh (idempotent).

set -euo pipefail

log() { printf "\033[1;34m[INFO]\033[0m %s\n" "$*"; }
err() { printf "\033[1;31m[ERR ]\033[0m %s\n" "$*" >&2; }

TARGET_USER="${SUDO_USER:-$USER}"
HOME_DIR="$(eval echo "~$TARGET_USER")"
BASHRC="$HOME_DIR/.bashrc"
DROPIN_DIR="$HOME_DIR/.bashrc.d"

[[ -d "$HOME_DIR" ]] || { err "Home dir not found: $HOME_DIR"; exit 1; }

# 1) Ensure drop-in dir
mkdir -p "$DROPIN_DIR"
chown "$TARGET_USER:$TARGET_USER" "$DROPIN_DIR"
chmod 0755 "$DROPIN_DIR"
log "Ensured drop-in directory: $DROPIN_DIR"

# 2) Ensure .bashrc exists
if [[ ! -f "$BASHRC" ]]; then
  touch "$BASHRC"
  chown "$TARGET_USER:$TARGET_USER" "$BASHRC"
  chmod 0644 "$BASHRC"
fi

# 3) Ensure include block in .bashrc (one-time)
INCLUDE_START="# >>> include ~/.bashrc.d/*.sh (setup-env) >>>"
INCLUDE_END="# <<< include ~/.bashrc.d/*.sh (setup-env) <<<"

if ! grep -qF "$INCLUDE_START" "$BASHRC"; then
  ts=$(date +%Y%m%d-%H%M%S)
  cp -a "$BASHRC" "$BASHRC.bak.$ts"
  chown "$TARGET_USER:$TARGET_USER" "$BASHRC.bak.$ts"
  log "Backup created: $BASHRC.bak.$ts"

  cat >>"$BASHRC" <<'EOF'

# >>> include ~/.bashrc.d/*.sh (setup-env) >>>
# Load per-user shell drop-ins, if any.
if [ -d "$HOME/.bashrc.d" ]; then
  for f in "$HOME/.bashrc.d"/*.sh; do
    [ -r "$f" ] && . "$f"
  done
fi
# <<< include ~/.bashrc.d/*.sh (setup-env) <<<
EOF
  chown "$TARGET_USER:$TARGET_USER" "$BASHRC"
  log "Include block appended to $BASHRC"
else
  log "Include block already present in $BASHRC — nothing to do."
fi

echo "Reload to apply:  source ~/.bashrc"
