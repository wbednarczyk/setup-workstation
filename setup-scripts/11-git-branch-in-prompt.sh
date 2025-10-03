#!/usr/bin/env bash
# 05.01-git-branch-in-prompt.sh
# Generates ~/.bashrc.d/50-git-branch.sh with exports + git branch prompt.
# Idempotent overwrite. No early 'return'; safe for non-interactive shells.

set -euo pipefail

log(){ printf "\033[1;34m[GIT-PROMPT]\033[0m %s\n" "$*"; }
err(){ printf "\033[1;31m[ERR ]\033[0m %s\n" "$*" >&2; }

TARGET_USER="${SUDO_USER:-$USER}"
HOME_DIR="$(eval echo "~$TARGET_USER")"
DROPIN_DIR="$HOME_DIR/.bashrc.d"
FILE="$DROPIN_DIR/50-git-branch.sh"

[[ -d "$HOME_DIR" ]] || { err "Home dir not found: $HOME_DIR"; exit 1; }
mkdir -p "$DROPIN_DIR"

cat >"$FILE" <<'EOF'
# ~/.bashrc.d/50-git-branch.sh
# Git prompt with branch + repo state (dirty/staged/untracked/stash/ahead/behind).
# Self-contained: defines exports + functions; sets PS1 only for interactive shells.

# --- tuning exports (override earlier if you want different behavior) ---
export GIT_PS1_SHOWDIRTYSTATE=1      # show * (unstaged), + (staged)
export GIT_PS1_SHOWUNTRACKEDFILES=1  # show % for untracked files
export GIT_PS1_SHOWSTASHSTATE=1      # show $ if stash exists
export GIT_PS1_SHOWUPSTREAM=auto     # show ↑N/↓M vs upstream

# --- helpers (bez kolorów w output) ---
__git_branch() {
  git symbolic-ref --quiet --short HEAD 2>/dev/null \
  || git rev-parse --short HEAD 2>/dev/null
}

__git_badges() {
  if [ "${GIT_PS1_SHOWDIRTYSTATE:-0}" = "1" ]; then
    git diff --quiet --ignore-submodules -- 2>/dev/null || printf '*'
    git diff --cached --quiet --ignore-submodules -- 2>/dev/null || printf '+'
  fi
  if [ "${GIT_PS1_SHOWUNTRACKEDFILES:-0}" = "1" ]; then
    if git ls-files --others --exclude-standard --directory --no-empty-directory 2>/dev/null \
       | head -n1 | grep -q .; then printf '%%'; fi
  fi
  if [ "${GIT_PS1_SHOWSTASHSTATE:-0}" = "1" ]; then
    git rev-parse -q --verify refs/stash >/dev/null 2>&1 && printf '$'
  fi
  if [ -n "${GIT_PS1_SHOWUPSTREAM:-}" ]; then
    if ab="$(git rev-list --left-right --count @{u}...HEAD 2>/dev/null)"; then
      set -- $ab; b="$1"; a="$2"
      [ "${a:-0}" -gt 0 ] && printf '↑%s' "$a"
      [ "${b:-0}" -gt 0 ] && printf '↓%s' "$b"
    fi
  fi
}

# ta funkcja już NIE zwraca kodów kolorów ani \[\]
__git_segment() {
  local b badges
  b="$(__git_branch)" || return 0
  [ -z "$b" ] && return 0
  badges="$(__git_badges)"
  if [ -n "$badges" ]; then
    printf "[%s{%s}]" "$b" "$badges"
  else
    printf "[%s]" "$b"
  fi
}

# --- kolory do PS1 (tu są \[ \], ale literalnie w PS1) ---
G_CLR="\[\033[01;32m\]"
B_CLR="\[\033[01;34m\]"
Y_CLR="\[\033[33m\]"
N_CLR="\[\033[00m\]"

# --- PS1: kolory poza $(...) ---
if [[ $- == *i* ]]; then
  if [ "${color_prompt:-yes}" = yes ]; then
    PS1='${debian_chroot:+($debian_chroot)}'"${G_CLR}"'\u@\h'"${N_CLR}"':'"${B_CLR}"'\w'"${N_CLR}"' '"${Y_CLR}"'$(__git_segment)'"${N_CLR}"' \$ '
  else
    PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w $(__git_segment) \$ '
  fi
fi
EOF

# normalize line endings (in case file got created with CRLF by accident)
sed -i 's/\r$//' "$FILE"

chown "$TARGET_USER:$TARGET_USER" "$FILE"
chmod 0644 "$FILE"

log "Drop-in written: $FILE"
echo "Reload your shell:  source ~/.bashrc"
