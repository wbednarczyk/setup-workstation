#!/usr/bin/env bash
# 03_git_ignore.sh
# Installs a predefined ~/.gitignore_global and configures git to use it.

set -euo pipefail

info() { printf "\033[1;34m[gitignore]\033[0m %s\n" "$*"; }

TARGET_USER="${SUDO_USER:-$USER}"
HOME_DIR="$(eval echo "~$TARGET_USER")"
IGNORE_FILE="$HOME_DIR/.gitignore_global"

cat >"$IGNORE_FILE" <<'EOF'
.DS_Store
Thumbs.db
*.swp
*.swo
.idea/
.vscode/
.env
.venv/
__pycache__/
node_modules/
EOF

chown "$TARGET_USER:$TARGET_USER" "$IGNORE_FILE"
chmod 0644 "$IGNORE_FILE"

# set in global git config
sudo -u "$TARGET_USER" git config --global core.excludesfile "$IGNORE_FILE"

info "Global gitignore installed at $IGNORE_FILE"