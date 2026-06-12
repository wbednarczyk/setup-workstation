#!/usr/bin/env bash
# 00-sudo-passwordless.sh
# Creates /etc/sudoers.d/99-<user>-nopasswd for passwordless sudo.

set -euo pipefail

log() { printf "\033[1;34m[INFO]\033[0m %s\n" "$*"; }
error() { printf "\033[1;31m[ERR ]\033[0m %s\n" "$*" >&2; }

if [[ $EUID -ne 0 ]]; then
  log "Re-executing with sudo..."
  exec sudo -E bash "$0" "$@"
fi

# Detect current user (prefer SUDO_USER if available)
TARGET_USER="${SUDO_USER:-$USER}"

if [[ -z "$TARGET_USER" || "$TARGET_USER" == "root" ]]; then
  error "Cannot determine non-root user. Run this script via sudo as a normal user."
  exit 1
fi

SUDOERS_FILE="/etc/sudoers.d/99-${TARGET_USER}-nopasswd"
ENTRY="${TARGET_USER} ALL=(ALL:ALL) NOPASSWD:ALL"

log "Creating sudoers entry for $TARGET_USER..."
echo "$ENTRY" > "$SUDOERS_FILE"
chmod 0440 "$SUDOERS_FILE"

# Validate with visudo
if visudo -c -f "$SUDOERS_FILE" >/dev/null 2>&1; then
  log "Sudoers entry installed successfully in $SUDOERS_FILE"
else
  error "visudo validation failed! Removing file to stay safe."
  rm -f "$SUDOERS_FILE"
  exit 1
fi

cat <<EOF
===============================================================
Passwordless sudo enabled for user: $TARGET_USER
File: $SUDOERS_FILE
Entry: $ENTRY
===============================================================
EOF
