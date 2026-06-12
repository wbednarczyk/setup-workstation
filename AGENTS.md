# Repository Instructions

This repository provisions a Windows 11 + Ubuntu WSL development workstation.
Keep changes small, script-first, and consistent with the existing numbered setup flow.

## Reference Docs

- [Repository map](docs/repository-map.md)
- [Script conventions](docs/script-conventions.md)
- [Project practises](docs/project-practises.md)
- [Bash script layout](docs/bash-scripts.md)
- [Windows WinGet configuration](docs/windows-winget.md)

## Project Shape

- `scripts/ubuntu/install/` contains Ubuntu/WSL package and tool installers.
- `scripts/ubuntu/setup/` contains user environment configuration scripts.
- `winget/` contains Windows 11 WinGet DSC configuration.
- `README.md` is intentionally minimal.
- `LICENSE` is MIT.

## Execution Model

- Scripts are numbered to imply ordering.
- Installers generally run before setup scripts.
- Prefer adding a new numbered script over embedding unrelated behavior in an existing script.
- Use dense two-digit numbering from `00`, incrementing by one within each
  script directory.
- Preserve idempotency: scripts should be safe to run repeatedly.
- Prefer explicit final verification when installing binaries or changing privileged state.

## Bash Conventions

- Use Bash scripts with `#!/usr/bin/env bash`.
- Use `set -euo pipefail`.
- Use small colored log helpers such as `log`, `info`, `warn`, `err`, or `error`.
- Keep scripts readable and mostly linear; add functions only when they reduce repeated logic.
- Use uppercase variable names for configuration and paths.
- Quote variable expansions.
- Use heredocs for generated dotfiles and config snippets.
- Use `mktemp` plus `trap` cleanup for downloaded temporary files.
- Use ASCII in new docs and scripts unless editing an existing non-ASCII snippet.

## Privilege And User Handling

- Scripts that need root usually self-escalate:

  ```bash
  if [[ $EUID -ne 0 ]]; then
    log "Re-executing with sudo..."
    exec sudo -E bash "$0" "$@"
  fi
  ```

- Scripts that must run as the normal user should reject root explicitly.
- Use `TARGET_USER="${SUDO_USER:-$USER}"` or `ORIG_USER="${SUDO_USER:-$USER}"` when writing user files.
- Resolve homes with `HOME_DIR="$(eval echo "~$TARGET_USER")"`.
- After writing files in a user's home, set ownership back to that user.
- Use conservative permissions:
  - directories: `0755`
  - regular user config files: `0644`
  - sudoers drop-ins: `0440`
  - executables installed to `/usr/local/bin`: `0755`

## Ubuntu/WSL Installers

- Target Ubuntu in WSL unless a script says otherwise.
- Use `apt-get`, not `apt`.
- Set `DEBIAN_FRONTEND=noninteractive` for apt-heavy installers.
- Install with `--no-install-recommends` where the existing pattern does.
- Base packages include CLI, shell, archive, network, and environment helpers.
- Docker is installed inside Ubuntu on WSL 2, without Docker Desktop or rootless mode.
- Docker setup enables WSL systemd when needed and may require rerunning after WSL shutdown.
- Nix uses the official multi-user installer and writes a Bash drop-in.
- Starship uses the official installer and writes a separate setup drop-in/config.
- kind installs the latest x64 Linux release into `/usr/local/bin`.

## User Environment Setup

- `~/.bashrc.d` is the preferred extension point.
- `scripts/ubuntu/setup/03-bashrc-dropin.sh` ensures `~/.bashrc` sources `~/.bashrc.d/*.sh`.
- Drop-ins should guard interactive-only behavior with:

  ```bash
  case $- in *i*) ;; *) return 0 2>/dev/null || exit 0 ;; esac
  ```

- Existing drop-in names use numeric prefixes to control ordering:
  - `00-editor.sh`
  - `10-nix.sh`
  - `50-git-branch.sh`
  - `90-starship.sh`
  - `99-direnv.sh`
- Setup scripts may overwrite their managed generated files, but should avoid clobbering unrelated user config.
- Back up existing user files before appending managed blocks.

## Git And Editor Setup

- Git config changes are append-only or set-if-absent.
- Do not overwrite `user.name`, `user.email`, or existing differing user preferences.
- Global gitignore is managed at `~/.gitignore_global`.
- Vim is the default editor and pager setup uses `less`.
- Vim configuration is a managed overwrite of `~/.vimrc`.

## Windows Configuration

- Windows setup is defined with WinGet DSC in `winget/w11.yaml`.
- Run WinGet configuration from an elevated Windows terminal.
- Keep resources idempotent with `TestScript` checks for custom scripts.
- Use `dependsOn` when resources require another package or setting first.
- Some Windows changes require restart; document rerun requirements when adding them.

## Validation

- For shell edits, run:

  ```bash
  bash -n path/to/script.sh
  ```

- For WinGet YAML edits, validate with:

  ```powershell
  winget configure validate --file .\setup-workstation\winget\w11.yaml
  ```

- Do not run installers during routine edits unless explicitly asked; many require network, sudo, or system changes.

## Change Hygiene

- Preserve unrelated untracked or modified files.
- Do not revert user changes unless explicitly requested.
- Prefer documenting newly discovered conventions in `docs/` and linking them from this file.
