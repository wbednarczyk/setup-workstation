#!/usr/bin/env bash
# 08-vimrc.sh
# Installs a minimal but useful ~/.vimrc for the current user (idempotent overwrite).

set -euo pipefail

log(){ printf "\033[1;34m[VIMRC]\033[0m %s\n" "$*"; }
err(){ printf "\033[1;31m[ERR ]\033[0m %s\n" "$*" >&2; }

TARGET_USER="${SUDO_USER:-$USER}"
HOME_DIR="$(eval echo "~$TARGET_USER")"
VIMRC="$HOME_DIR/.vimrc"

[[ -d "$HOME_DIR" ]] || { err "Home dir not found: $HOME_DIR"; exit 1; }

cat >"$VIMRC" <<'EOF'
" ~/.vimrc - basic configuration

syntax on               " enable syntax highlighting
set number              " show line numbers
set tabstop=2           " number of spaces a <Tab> counts for
set shiftwidth=2        " number of spaces used for autoindent
set expandtab           " convert tabs to spaces
set autoindent          " keep indenting on new lines
set smartindent         " smart C-style indenting
set cursorline          " highlight current line
set showmatch           " highlight matching brackets
set incsearch           " incremental search
set ignorecase          " case-insensitive search...
set smartcase           " ...unless pattern contains uppercase
set hlsearch            " highlight all search results
set clipboard=unnamedplus " use system clipboard
set background=dark     " better default for dark terminals

" Status line
set laststatus=2
set ruler

" Colorscheme (safe fallback)
if &t_Co >= 256
  colorscheme desert
endif
EOF

chown "$TARGET_USER:$TARGET_USER" "$VIMRC"
chmod 0644 "$VIMRC"

log "Installed ~/.vimrc for $TARGET_USER"
