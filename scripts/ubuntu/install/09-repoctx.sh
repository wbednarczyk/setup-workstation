#!/usr/bin/env bash
# 09-repoctx.sh
# Installs the latest repoctx release into /usr/local/bin for x64 Linux. Safe to re-run.

set -euo pipefail

log(){ printf "\033[1;34m[REPOCTX]\033[0m %s\n" "$*"; }
err(){ printf "\033[1;31m[ERR ]\033[0m %s\n" "$*" >&2; }

if [[ $EUID -ne 0 ]]; then
  log "Re-executing with sudo..."
  exec sudo -E bash "$0" "$@"
fi

if [[ "$(uname -m)" != "x86_64" ]]; then
  err "Unsupported architecture: $(uname -m). This installer supports x64 Linux only."
  exit 1
fi

export DEBIAN_FRONTEND=noninteractive

apt-get update -y
apt-get install -y --no-install-recommends ca-certificates curl tar

LATEST_TAG="$(
  curl -fsSL -o /dev/null -w '%{url_effective}' https://github.com/mikolajmikolajczyk/repoctx/releases/latest |
    sed 's#.*/##'
)"

if [[ -z "${LATEST_TAG}" || "${LATEST_TAG}" != v* ]]; then
  err "Could not determine latest repoctx release."
  exit 1
fi

LATEST_VERSION="${LATEST_TAG#v}"

if command -v repoctx >/dev/null 2>&1 && repoctx --version | grep -q "${LATEST_VERSION}"; then
  log "repoctx already installed: $(repoctx --version)"
  exit 0
fi

TMP_DIR="$(mktemp -d)"
cleanup() {
  rm -rf "$TMP_DIR"
}
trap cleanup EXIT

ARCHIVE_NAME="repoctx-${LATEST_VERSION}-x86_64-unknown-linux-gnu.tar.gz"
ARCHIVE_URL="https://github.com/mikolajmikolajczyk/repoctx/releases/download/${LATEST_TAG}/${ARCHIVE_NAME}"
REPOCTX_BIN="$TMP_DIR/repoctx"

log "Downloading repoctx ${LATEST_VERSION} for x86_64-unknown-linux-gnu..."
curl -fsSL -o "$TMP_DIR/$ARCHIVE_NAME" "$ARCHIVE_URL"
curl -fsSL -o "$TMP_DIR/$ARCHIVE_NAME.sha256" "$ARCHIVE_URL.sha256"

(
  cd "$TMP_DIR"
  sha256sum -c "$ARCHIVE_NAME.sha256"
)

tar -xzf "$TMP_DIR/$ARCHIVE_NAME" -C "$TMP_DIR"

if [[ ! -x "$REPOCTX_BIN" ]]; then
  REPOCTX_BIN="$(find "$TMP_DIR" -type f -name repoctx -perm /111 -print -quit)"
fi

if [[ -z "${REPOCTX_BIN}" || ! -x "$REPOCTX_BIN" ]]; then
  err "repoctx binary not found in release archive."
  exit 1
fi

install -m 0755 "$REPOCTX_BIN" /usr/local/bin/repoctx

if ! command -v repoctx >/dev/null 2>&1; then
  err "repoctx not found after install."
  exit 1
fi

repoctx --version
log "Install/upgrade done."
