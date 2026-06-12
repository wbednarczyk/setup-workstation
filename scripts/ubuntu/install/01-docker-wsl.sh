#!/usr/bin/env bash
# install-docker-wsl.sh
# Installs Docker Engine (daemon + CLI) inside Ubuntu on WSL 2.
# No Docker Desktop, no Windows scheduler, no rootless. Idempotent.
# Supports selecting Docker major version (default: 23).

set -euo pipefail

log()   { printf "\033[1;34m[INFO]\033[0m %s\n" "$*"; }
warn()  { printf "\033[1;33m[WARN]\033[0m %s\n" "$*"; }
error() { printf "\033[1;31m[ERR ]\033[0m %s\n" "$*" >&2; }

require_root() {
  if [[ $EUID -ne 0 ]]; then
    log "Re-executing with sudo..."
    exec sudo -E bash "$0" "$@"
  fi
}

ORIG_USER="${SUDO_USER:-$USER}"

# --- Parse args (Docker major version) ---
DOCKER_MAJOR="23"
while [[ $# -gt 0 ]]; do
  case "$1" in
    --docker-version|--version)
      [[ $# -ge 2 ]] || { error "Missing value for $1"; exit 2; }
      DOCKER_MAJOR="$2"; shift 2;;
    --docker-version=*|--version=*)
      DOCKER_MAJOR="${1#*=}"; shift;;
    -*)
      warn "Unknown option: $1 (ignored)"; shift;;
    *)
      if [[ "$1" =~ ^[0-9]+$ ]]; then
        DOCKER_MAJOR="$1"
      else
        warn "Unrecognized positional arg '$1' (ignored)"
      fi
      shift;;
  esac
done

require_root "$@"

# --- Validate distro ---
if [[ -f /etc/os-release ]]; then . /etc/os-release; else error "/etc/os-release missing"; exit 1; fi
if [[ "${ID:-}" != "ubuntu" ]]; then warn "Non-Ubuntu distro detected (ID=${ID:-?})."; fi

export DEBIAN_FRONTEND=noninteractive

# --- Ensure systemd (WSL) ---
if [[ ! -d /run/systemd/system ]]; then
  warn "systemd is not active in this WSL session."
  if ! grep -qs '^systemd=true' /etc/wsl.conf 2>/dev/null; then
    log "Enabling systemd in /etc/wsl.conf ..."
    install -D -m 0644 /dev/stdin /etc/wsl.conf <<'EOF'
[boot]
systemd=true
EOF
  else
    log "systemd=true already present in /etc/wsl.conf"
  fi

  WSL_EXE="/mnt/c/Windows/System32/wsl.exe"
  if [[ -x "$WSL_EXE" ]]; then
    cat <<'MSG'
===============================================================
Systemd has been enabled. WSL will now shutdown automatically.
After it closes, reopen your Ubuntu terminal and re-run:
  ./install-docker-wsl.sh
  (optionally with: --version <major>, default 23)
===============================================================
MSG
    "$WSL_EXE" --shutdown
    exit 0
  else
    warn "Cannot find wsl.exe at $WSL_EXE. Please run 'wsl --shutdown' from Windows manually."
    exit 1
  fi
fi

log "systemd is active. Proceeding (Docker major requested: ${DOCKER_MAJOR})."

# --- Docker repo ---
apt-get update
apt-get install -y ca-certificates curl gnupg lsb-release apt-transport-https

install -m 0755 -d /etc/apt/keyrings
if [[ ! -f /etc/apt/keyrings/docker.gpg ]]; then
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
  chmod a+r /etc/apt/keyrings/docker.gpg
else
  log "Docker GPG key already present."
fi

echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu ${UBUNTU_CODENAME} stable" \
  > /etc/apt/sources.list.d/docker.list

apt-get update

# --- Resolve target version for requested major ---
pick_docker_version() {
  local major="$1"
  apt-cache madison docker-ce \
    | awk -F'|' '{gsub(/ /,"",$2); print $2}' \
    | grep -E '^[0-9]+:' \
    | grep -E "^([0-9]+:)?${major}\." \
    | head -n1
}

TARGET_VER="$(pick_docker_version "$DOCKER_MAJOR" || true)"

if [[ -n "${TARGET_VER:-}" ]]; then
  log "Pinning Docker packages to version: $TARGET_VER"
  apt-get install -y \
    "docker-ce=${TARGET_VER}" \
    "docker-ce-cli=${TARGET_VER}" \
    containerd.io \
    "docker-buildx-plugin=${TARGET_VER}" \
    "docker-compose-plugin=${TARGET_VER}"
else
  warn "No docker-ce version found for major ${DOCKER_MAJOR}. Installing latest available (un-pinned)."
  apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
fi

# --- Enable & start service ---
systemctl enable --now docker
log "Docker service enabled and started."

# --- Add current user to docker group ---
if id -nG "${ORIG_USER}" | grep -qw docker; then
  log "User '${ORIG_USER}' is already in 'docker' group."
  NEWGROUP_HINT=
else
  usermod -aG docker "${ORIG_USER}"
  log "Added '${ORIG_USER}' to 'docker' group."
  NEWGROUP_HINT=1
fi

# --- Finish ---
cat <<EOF
===============================================================
Docker Engine installation finished.

Selected major: ${DOCKER_MAJOR}
Pinned version: ${TARGET_VER:-<latest>}

Next steps:
- ${NEWGROUP_HINT:+Run 'newgrp docker' now OR open a new terminal so group changes take effect.
- }Test:   docker run --rm hello-world
- Logs:   journalctl -u docker -f
- Status: systemctl status docker

On WSL2:
- Docker starts automatically with systemd when Ubuntu starts.
===============================================================
EOF
