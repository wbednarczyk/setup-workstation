#!/usr/bin/env bash
# 11-rtk.sh
# Installs the latest rtk (Rust Token Killer) release into /usr/local/bin for
# Linux. Safe to re-run.

set -euo pipefail

log(){ printf "\033[1;34m[RTK]\033[0m %s\n" "$*"; }
err(){ printf "\033[1;31m[ERR ]\033[0m %s\n" "$*" >&2; }

if [[ $EUID -ne 0 ]]; then
  log "Re-executing with sudo..."
  exec sudo -E bash "$0" "$@"
fi

case "$(uname -m)" in
  x86_64)
    TARGET="x86_64-unknown-linux-musl"
    ;;
  aarch64|arm64)
    TARGET="aarch64-unknown-linux-gnu"
    ;;
  *)
    err "Unsupported architecture: $(uname -m). This installer supports x64 and arm64 Linux only."
    exit 1
    ;;
esac

export DEBIAN_FRONTEND=noninteractive

apt-get update -y
apt-get install -y --no-install-recommends ca-certificates curl tar

REPO="rtk-ai/rtk"
LATEST_TAG="$(
  curl -fsSL -o /dev/null -w '%{url_effective}' "https://github.com/${REPO}/releases/latest" |
    sed 's#.*/##'
)"

if [[ -z "${LATEST_TAG}" || "${LATEST_TAG}" != v* ]]; then
  err "Could not determine latest rtk release."
  exit 1
fi

LATEST_VERSION="${LATEST_TAG#v}"

if [[ -x /usr/local/bin/rtk ]] && /usr/local/bin/rtk --version | grep -q "${LATEST_VERSION}"; then
  log "rtk already installed: $(/usr/local/bin/rtk --version)"
  exit 0
fi

TMP_DIR="$(mktemp -d)"
cleanup() {
  rm -rf "$TMP_DIR"
}
trap cleanup EXIT

ARCHIVE_NAME="rtk-${TARGET}.tar.gz"
ARCHIVE_URL="https://github.com/${REPO}/releases/download/${LATEST_TAG}/${ARCHIVE_NAME}"
CHECKSUMS_URL="https://github.com/${REPO}/releases/download/${LATEST_TAG}/checksums.txt"
RTK_BIN="$TMP_DIR/rtk"

log "Downloading rtk ${LATEST_VERSION} for ${TARGET}..."
curl -fsSL -o "$TMP_DIR/$ARCHIVE_NAME" "$ARCHIVE_URL"
curl -fsSL -o "$TMP_DIR/checksums.txt" "$CHECKSUMS_URL"

EXPECTED_SHA256="$(
  awk -v name="$ARCHIVE_NAME" '$2 == name { print $1; exit }' "$TMP_DIR/checksums.txt"
)"

if [[ -z "${EXPECTED_SHA256}" ]]; then
  err "Checksum for ${ARCHIVE_NAME} not found in checksums.txt."
  exit 1
fi

ACTUAL_SHA256="$(sha256sum "$TMP_DIR/$ARCHIVE_NAME" | awk '{print $1}')"

if [[ "$EXPECTED_SHA256" != "$ACTUAL_SHA256" ]]; then
  err "Checksum mismatch for ${ARCHIVE_NAME}."
  exit 1
fi

if tar -tzf "$TMP_DIR/$ARCHIVE_NAME" | grep -qE '^/|(^|/)\.\.(/|$)'; then
  err "Release archive contains unsafe paths."
  exit 1
fi

tar -xzf "$TMP_DIR/$ARCHIVE_NAME" -C "$TMP_DIR"

if [[ ! -x "$RTK_BIN" ]]; then
  RTK_BIN="$(find "$TMP_DIR" -type f -name rtk -perm /111 -print -quit)"
fi

if [[ -z "${RTK_BIN}" || ! -x "$RTK_BIN" ]]; then
  err "rtk binary not found in release archive."
  exit 1
fi

install -m 0755 "$RTK_BIN" /usr/local/bin/rtk

if [[ ! -x /usr/local/bin/rtk ]]; then
  err "rtk not found after install."
  exit 1
fi

/usr/local/bin/rtk --version
log "Install/upgrade done."
