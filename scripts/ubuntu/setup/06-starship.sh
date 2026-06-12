#!/usr/bin/env bash
# 06-starship.sh
# Enables Starship prompt in Bash via ~/.bashrc.d and writes minimal config.
# Safe for WSL / Ubuntu setups.

set -euo pipefail
log(){ printf "\033[1;34m[STARSHIP]\033[0m %s\n" "$*"; }
err(){ printf "\033[1;31m[ERR ]\033[0m %s\n" "$*" >&2; }

# --- sanity ---
if ! command -v starship >/dev/null 2>&1; then
  err "starship not found. Install it first (e.g. 12-install-starship.sh)."
  exit 1
fi

TARGET_USER="${SUDO_USER:-$USER}"
HOME_DIR="$(eval echo "~$TARGET_USER")"
DROPIN_DIR="$HOME_DIR/.bashrc.d"
DROPIN_FILE="$DROPIN_DIR/90-starship.sh"
CONFIG_DIR="$HOME_DIR/.config"
STARSHIP_TOML="$CONFIG_DIR/starship.toml"
CACHE_DIR="$HOME_DIR/.cache/starship"

# --- ensure config ---
mkdir -p "$CONFIG_DIR"
cat >"$STARSHIP_TOML" <<'EOF'
# ~/.config/starship.toml
# Minimal, fast prompt for Bash/WSL: username@hostname + dir + git + $.

add_newline = false
command_timeout = 1000

format = "$username$hostname$directory$git_branch$git_status$character"

[username]
show_always = true
style_user = "bold green"
style_root = "bold red"
format = "[$user]($style)"

[hostname]
ssh_only = false
format = "[@$hostname](bold green) "
disabled = false

[directory]
style = "bold bright_blue"
truncation_length = 0  #no truncation
truncate_to_repo = false  #show full path even in git repo
read_only = " "
format = "[$path]($style) "

[git_branch]
symbol = " "
style = "yellow"
format = "[$symbol$branch]($style) "

[git_status]
style = "yellow"
conflicted = "⚠"
staged = "+"
modified = "*"
untracked = "%"
stashed = "$"
ahead = "↑${count}"
behind = "↓${count}"
diverged = "↑${ahead_count}↓${behind_count}"
format = "[$conflicted$staged$modified$untracked$stashed$ahead_behind]($style) "

[character]
# Uwaga: używamy *pojedynczych* cudzysłowów i \$
# żeby Starship dostał dosłowny znak dolara, a TOML nie marudził.
success_symbol = '[\$](bold green) '
error_symbol   = '[\$](bold red) '
EOF

log "Wrote Starship config: $STARSHIP_TOML"

# --- ensure cache dir & fix perms ---
mkdir -p "$CACHE_DIR" || true
if ! test -w "$CACHE_DIR"; then
  log "Fixing cache ownership in $CACHE_DIR (may ask for sudo)…"
  sudo chown -R "$TARGET_USER:$TARGET_USER" "$HOME_DIR/.cache" || true
fi
chmod 700 "$HOME_DIR/.cache" "$CACHE_DIR" 2>/dev/null || true

# --- create drop-in ---
mkdir -p "$DROPIN_DIR"
cat >"$DROPIN_FILE" <<'EOF'
# ~/.bashrc.d/90-starship.sh
# Enable Starship prompt for interactive Bash shells.
case $- in *i*) ;; *) return 0 2>/dev/null || exit 0 ;; esac

export XDG_CACHE_HOME="$HOME/.cache"
export STARSHIP_CACHE="$XDG_CACHE_HOME/starship"
export STARSHIP_CONFIG="$HOME/.config/starship.toml"

eval "$(starship init bash)"
EOF

# --- fix ownership & perms ---
chown -R "$TARGET_USER:$TARGET_USER" "$DROPIN_DIR" "$CONFIG_DIR"
chmod 0644 "$DROPIN_FILE" "$STARSHIP_TOML"

log "Drop-in enabled at: $DROPIN_FILE"
echo "Reload your shell:  source ~/.bashrc"
echo "If you see no icons, switch your terminal font to a Nerd Font (optional)."
