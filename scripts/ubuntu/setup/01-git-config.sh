#!/usr/bin/env bash
# 01-git-config.sh
# Append-only git config: ensure aliases, editor (if unset), and GitHub SSH insteadOf.
# Does NOT overwrite user.name / user.email or existing differing values.

set -euo pipefail

info() { printf "\033[1;34m[gitcfg]\033[0m %s\n" "$*"; }
as_user() { sudo -u "${TARGET_USER}" -H bash -lc "$*"; }

TARGET_USER="${SUDO_USER:-$USER}"
if ! id "$TARGET_USER" >/dev/null 2>&1; then
  echo "User '$TARGET_USER' not found" >&2; exit 1
fi

# Helpers: set key only if absent; for multi-valued keys, add value if not present.
ensure_key_if_absent() {
  local key="$1" val="$2"
  if as_user "git config --global --get \"$key\" >/dev/null 2>&1"; then
    info "keep: $key already set ($(as_user "git config --global --get \"$key\""))"
  else
    info "set : $key = $val"
    as_user "git config --global \"$key\" \"$val\""
  fi
}

ensure_multivalue_contains() {
  local key="$1" val="$2"
  if as_user "git config --global --get-all \"$key\" | grep -qx -- \"$val\""; then
    info "keep: $key already contains '$val'"
  else
    info "add : $key += $val"
    as_user "git config --global --add \"$key\" \"$val\""
  fi
}

# 1) Aliases (only if each is missing)
ensure_key_if_absent "alias.co" "checkout"
ensure_key_if_absent "alias.st" "status"
ensure_key_if_absent "alias.br" "branch"
ensure_key_if_absent "alias.ci" "commit"

# 2) core.editor (only if unset)
if as_user "git config --global --get core.editor >/dev/null 2>&1"; then
  info "keep: core.editor already set ($(as_user "git config --global --get core.editor"))"
else
  info "set : core.editor = vim"
  as_user "git config --global core.editor vim"
fi

# 3) Use SSH for GitHub via insteadOf (append only if missing)
#    url."git@github.com:".insteadof can be multi-valued; we add https://github.com/ if absent.
ensure_multivalue_contains 'url."git@github.com:".insteadof' "https://github.com/"

# Done
info "Done"
