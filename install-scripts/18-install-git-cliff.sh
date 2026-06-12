#!/usr/bin/env bash
# 18-install-git-cliff.sh
# Installs the latest git-cliff release into /usr/local/bin for x64 Linux. Safe to re-run.

set -euo pipefail

log(){ printf "\033[1;34m[GIT-CLIFF]\033[0m %s\n" "$*"; }
err(){ printf "\033[1;31m[ERR ]\033[0m %s\n" "$*" >&2; }

if [[ $EUID -ne 0 ]]; then
  log "Re-executing with sudo..."
  exec sudo -E bash "$0" "$@"
fi

if [[ "$(uname -m)" != "x86_64" ]]; then
  err "Unsupported architecture: $(uname -m). This installer supports x64 Linux only."
  exit 1
fi

apt-get update -y
apt-get install -y --no-install-recommends ca-certificates curl tar

LATEST_TAG="$(
  curl -fsSL -o /dev/null -w '%{url_effective}' https://github.com/orhun/git-cliff/releases/latest |
    sed 's#.*/##'
)"

if [[ -z "${LATEST_TAG}" || "${LATEST_TAG}" != v* ]]; then
  err "Could not determine latest git-cliff release."
  exit 1
fi

LATEST_VERSION="${LATEST_TAG#v}"

if command -v git-cliff >/dev/null 2>&1 && git-cliff --version | grep -q "${LATEST_VERSION}"; then
  log "git-cliff already installed: $(git-cliff --version)"
  exit 0
fi

TMP_DIR="$(mktemp -d)"
cleanup() {
  rm -rf "$TMP_DIR"
}
trap cleanup EXIT

ARCHIVE_NAME="git-cliff-${LATEST_VERSION}-x86_64-unknown-linux-gnu.tar.gz"
GIT_CLIFF_BIN="$TMP_DIR/git-cliff-${LATEST_VERSION}/git-cliff"

log "Downloading git-cliff ${LATEST_VERSION} for x86_64-unknown-linux-gnu..."
curl -fsSL -o "$TMP_DIR/$ARCHIVE_NAME" \
  "https://github.com/orhun/git-cliff/releases/download/${LATEST_TAG}/${ARCHIVE_NAME}"

tar -xzf "$TMP_DIR/$ARCHIVE_NAME" -C "$TMP_DIR"

if [[ ! -x "$GIT_CLIFF_BIN" ]]; then
  err "git-cliff binary not found in release archive."
  exit 1
fi

install -m 0755 "$GIT_CLIFF_BIN" /usr/local/bin/git-cliff

if ! command -v git-cliff >/dev/null 2>&1; then
  err "git-cliff not found after install."
  exit 1
fi

git-cliff --version
log "Install/upgrade done."
