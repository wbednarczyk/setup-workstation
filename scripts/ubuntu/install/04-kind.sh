#!/usr/bin/env bash
# 04-kind.sh
# Installs the latest kind release into /usr/local/bin for x64 Linux. Safe to re-run.

set -euo pipefail

log(){ printf "\033[1;34m[KIND]\033[0m %s\n" "$*"; }
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
apt-get install -y --no-install-recommends ca-certificates curl

LATEST_VERSION="$(
  curl -fsSL -o /dev/null -w '%{url_effective}' https://github.com/kubernetes-sigs/kind/releases/latest |
    sed 's#.*/##'
)"

if [[ -z "${LATEST_VERSION}" || "${LATEST_VERSION}" != v* ]]; then
  err "Could not determine latest kind release."
  exit 1
fi

if command -v kind >/dev/null 2>&1 && kind version | grep -q "${LATEST_VERSION}"; then
  log "kind already installed: $(kind version)"
  exit 0
fi

TMP_DIR="$(mktemp -d)"
cleanup() {
  rm -rf "$TMP_DIR"
}
trap cleanup EXIT

log "Downloading kind ${LATEST_VERSION} for linux-amd64..."
curl -fsSL -o "$TMP_DIR/kind" "https://kind.sigs.k8s.io/dl/${LATEST_VERSION}/kind-linux-amd64"

chmod +x "$TMP_DIR/kind"
install -m 0755 "$TMP_DIR/kind" /usr/local/bin/kind

if ! command -v kind >/dev/null 2>&1; then
  err "kind not found after install."
  exit 1
fi

kind version
log "Install/upgrade done."
