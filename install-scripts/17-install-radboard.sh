#!/usr/bin/env bash
# 17-install-radboard.sh
# Installs Radboard for Radicle from the official Debian package. Safe to re-run.

set -euo pipefail

log(){ printf "\033[1;34m[RADBOARD]\033[0m %s\n" "$*"; }
err(){ printf "\033[1;31m[ERR ]\033[0m %s\n" "$*" >&2; }

if [[ $EUID -ne 0 ]]; then
  log "Re-executing with sudo..."
  exec sudo -E bash "$0" "$@"
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RADICLE_INSTALLER="$SCRIPT_DIR/16-install-radicle.sh"
RADBOARD_DEB_URL="https://dl.mikolajczyk.org/radboard/latest/radboard-amd64.deb"
RADBOARD_VERSION_URL="https://dl.mikolajczyk.org/radboard/version"
ARCH="$(dpkg --print-architecture)"
RADBOARD_BIN="/usr/bin/radboard"
RADBOARD_WRAPPER="/usr/local/bin/radboard"
RADBOARD_DESKTOP_FILE="/usr/share/applications/radboard.desktop"

if [[ "$ARCH" != "amd64" ]]; then
  err "Radboard Debian package is only available for amd64; detected: $ARCH"
  exit 1
fi

export DEBIAN_FRONTEND=noninteractive

apt-get update -y
apt-get install -y --no-install-recommends ca-certificates curl

if ! command -v rad >/dev/null 2>&1; then
  if [[ ! -f "$RADICLE_INSTALLER" ]]; then
    err "Radicle is required, but installer not found: $RADICLE_INSTALLER"
    exit 1
  fi

  log "Radicle not found; installing dependency first..."
  bash "$RADICLE_INSTALLER"
else
  log "Radicle already present."
fi

TMP_DIR="$(mktemp -d)"
cleanup() {
  rm -rf "$TMP_DIR"
}
trap cleanup EXIT

RADBOARD_VERSION="$(curl -fsSL "$RADBOARD_VERSION_URL" 2>/dev/null || true)"
if [[ -n "$RADBOARD_VERSION" ]]; then
  log "Latest Radboard version: $RADBOARD_VERSION"
fi

log "Downloading Radboard Debian package..."
curl -fsSL -o "$TMP_DIR/radboard-amd64.deb" "$RADBOARD_DEB_URL"
chmod a+r "$TMP_DIR/radboard-amd64.deb"

apt-get install -y --no-install-recommends "$TMP_DIR/radboard-amd64.deb"

if [[ -x "$RADBOARD_BIN" ]]; then
  log "Installing Radboard launcher wrapper..."
  install -m 0755 -d "$(dirname "$RADBOARD_WRAPPER")"
  cat > "$RADBOARD_WRAPPER" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

if grep -qi microsoft /proc/sys/kernel/osrelease 2>/dev/null; then
  export WEBKIT_DISABLE_DMABUF_RENDERER="${WEBKIT_DISABLE_DMABUF_RENDERER:-1}"
  export LIBGL_ALWAYS_SOFTWARE="${LIBGL_ALWAYS_SOFTWARE:-1}"
fi

exec /usr/bin/radboard "$@"
EOF
  chmod 0755 "$RADBOARD_WRAPPER"
fi

if grep -qi microsoft /proc/sys/kernel/osrelease 2>/dev/null && [[ -f "$RADBOARD_DESKTOP_FILE" ]]; then
  log "Updating Radboard desktop launcher for WSL rendering..."
  sed -i 's|^Exec=.*|Exec=env WEBKIT_DISABLE_DMABUF_RENDERER=1 LIBGL_ALWAYS_SOFTWARE=1 /usr/bin/radboard|' \
    "$RADBOARD_DESKTOP_FILE"
fi

if ! command -v radboard >/dev/null 2>&1; then
  err "radboard not found after install."
  exit 1
fi

dpkg-query -W -f='radboard ${Version}\n' radboard
log "Install/upgrade done."
