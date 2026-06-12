# Script Conventions

These conventions were inferred from every script in `scripts/ubuntu/install/`
and `scripts/ubuntu/setup/`.

## File Naming

- Scripts are numbered with two-digit prefixes.
- Names use kebab case in the filesystem.
- New related scripts should use the next available numeric prefix in the
  appropriate directory.
- Use dense numbering starting at `00` and incrementing by one.
- Renumber only during an intentional organization pass.

## Bash Baseline

Use this baseline for new shell scripts:

```bash
#!/usr/bin/env bash
set -euo pipefail
```

Logging is usually done with small `printf` helpers:

```bash
log(){ printf "\033[1;34m[NAME]\033[0m %s\n" "$*"; }
err(){ printf "\033[1;31m[ERR ]\033[0m %s\n" "$*" >&2; }
```

Existing scripts use several tag names, including `BASE`, `INFO`, `STARSHIP`,
`NIX`, `KIND`, `gitcfg`, `gitignore`, `GIT-PROMPT`, `EDITOR`, `NIX-DIRENV`,
and `VIMRC`.

## Idempotency

- Prefer checking current state before changing it.
- Installer scripts should verify the installed command after installation.
- User setup scripts may overwrite files they fully own and generate.
- For shared or user-authored files, append managed blocks only once.
- Back up a user file before appending a managed block.
- Use `grep` checks for existing settings before appending config lines.
- Use `visudo -c -f` after writing sudoers files.

## Privileges

Many installers self-escalate with `sudo` when root is required. Scripts that
write user files usually run as the current user but still honor `SUDO_USER`.

Use this pattern for root-required scripts:

```bash
if [[ $EUID -ne 0 ]]; then
  log "Re-executing with sudo..."
  exec sudo -E bash "$0" "$@"
fi
```

Use this pattern for user-targeted files:

```bash
TARGET_USER="${SUDO_USER:-$USER}"
HOME_DIR="$(eval echo "~$TARGET_USER")"
```

Validate the home directory before writing into it:

```bash
[[ -d "$HOME_DIR" ]] || { err "Home dir not found: $HOME_DIR"; exit 1; }
```

## File Generation

- Generated shell drop-ins live in `~/.bashrc.d`.
- Generated app config lives under the user's home, typically `~/.config`.
- Use heredocs for generated files.
- Restore ownership with `chown "$TARGET_USER:$TARGET_USER"`.
- Use `chmod 0644` for generated config files.
- Use `chmod 0755` for directories and installed executables.
- Use `chmod 0440` for sudoers files.

## Shell Drop-Ins

The repository standardizes on a Bash drop-in directory:

```bash
~/.bashrc.d/*.sh
```

The managed `.bashrc` include block checks that the directory exists and then
sources readable `*.sh` files.

Interactive-only drop-ins should start with:

```bash
case $- in *i*) ;; *) return 0 2>/dev/null || exit 0 ;; esac
```

Known drop-in ordering:

- `00-editor.sh`: editor and pager exports.
- `10-nix.sh`: Nix daemon profile loading.
- `50-git-branch.sh`: Git branch prompt.
- `90-starship.sh`: Starship prompt.
- `99-direnv.sh`: direnv hook.

Starship and the manual Git prompt are both prompt implementations. Avoid
enabling conflicting prompt customizations without documenting precedence.

## Package And Tool Installation

- Use `apt-get` for Ubuntu scripts.
- Prefer `apt-get install -y --no-install-recommends` when installing a small
  dependency set.
- Use `ca-certificates` and `curl` before remote downloads.
- Use `curl -fsSL` for remote scripts and binaries.
- Place manually downloaded executables in `/usr/local/bin`.
- Clean temporary download files with `trap`.
- Keep architecture checks explicit when a download URL is architecture-specific.

## Git Configuration

Git setup is intentionally non-destructive:

- Add aliases only if missing.
- Set `core.editor` only if absent.
- Add multi-value `insteadOf` entries only if the value is not already present.
- Do not manage `user.name` or `user.email`.
- Global excludes are intentionally managed by
  `scripts/ubuntu/setup/02-gitignore-global.sh`.

## Validation Commands

For shell scripts:

```bash
bash -n scripts/ubuntu/install/name.sh
bash -n scripts/ubuntu/setup/name.sh
```

For the Windows configuration:

```powershell
winget configure validate --file .\setup-workstation\winget\w11.yaml
```

Avoid running full installers as a validation shortcut unless the change
requires it and the user has approved system changes.
