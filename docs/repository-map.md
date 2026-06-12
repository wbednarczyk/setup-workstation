# Repository Map

This repository contains workstation bootstrap automation for a Windows 11 host
and an Ubuntu WSL environment.

## Root

- `README.md`: Minimal repository title.
- `LICENSE`: MIT license.
- `AGENTS.md`: Contributor and agent instructions for this repository.

## `install-scripts/`

Installer scripts provision system packages and developer tools inside Ubuntu,
primarily for WSL.

- `10-install-base-packages.sh`: Installs common Ubuntu packages:
  certificates, curl/wget, build tools, shell utilities, archive tools, `jq`,
  `yq`, `fzf`, `ripgrep`, `direnv`, and network tools.
- `11-install-docker-wsl.sh`: Installs Docker Engine inside Ubuntu on WSL 2,
  enables systemd if required, configures Docker's apt repository, installs a
  selected Docker major version when available, starts Docker, and adds the
  original user to the `docker` group.
- `12-install-starship.sh`: Installs Starship into `/usr/local/bin` using the
  official installer.
- `13-install-nix.sh`: Installs Nix using the official multi-user daemon
  installer and writes a Bash drop-in for Nix profile loading.
- `14-install-kind.sh`: Installs the latest x64 Linux kind binary into
  `/usr/local/bin`.
- `15-install-gh-cli.sh`: Installs GitHub CLI from GitHub's official apt
  repository and verifies the `gh` command.
- `16-install-radicle.sh`: Installs the Radicle toolchain from Radicle's
  official apt repository and verifies the `rad` command.
- `17-install-radboard.sh`: Installs Radboard from the official Debian package,
  installing Radicle first with `16-install-radicle.sh` when `rad` is missing,
  adds a WSL rendering wrapper, and verifies the `radboard` command.
- `18-install-git-cliff.sh`: Installs the latest x64 Linux git-cliff binary
  into `/usr/local/bin` and verifies the `git-cliff` command.
- `19-install-repoctx.sh`: Installs the latest x64 Linux repoctx binary into
  `/usr/local/bin`, verifies the release checksum, and verifies the `repoctx`
  command.

## `setup-scripts/`

Setup scripts configure the user's shell, editor, Git defaults, and dotfiles.

- `01-sudo-passwordless.sh`: Writes and validates a sudoers drop-in for
  passwordless sudo for the invoking non-root user.
- `02-git-config-merge.sh`: Adds Git aliases, default editor, and GitHub SSH
  `insteadOf` configuration without overwriting existing differing values.
- `03-gitignore-global.sh`: Writes `~/.gitignore_global` and configures Git to
  use it.
- `10-setup-bashrc.d-dropin.sh`: Creates `~/.bashrc.d` and appends a managed
  include block to `~/.bashrc`, backing up the original file first.
- `11-git-branch-in-prompt.sh`: Writes a self-contained Bash prompt drop-in
  with Git branch and repository status.
- `12-set-vim-as-default-editor.sh`: Writes `~/.bashrc.d/00-editor.sh` to set
  `EDITOR`, `VISUAL`, and `PAGER`.
- `13-setup-starship-dropin.sh`: Writes `~/.config/starship.toml` and
  `~/.bashrc.d/90-starship.sh`.
- `14-setup-nix-direnv-dropin.sh`: Writes `~/.bashrc.d/99-direnv.sh` and
  enables Nix flakes in `~/.config/nix/nix.conf` if absent.
- `21-setup-vimrc.sh`: Writes a managed `~/.vimrc` with basic editor settings.

## `winget/`

Windows 11 host configuration using WinGet DSC.

- `winget/readme.md`: Requirements and commands for validating and applying
  the WinGet configuration.
- `winget/w11.yaml`: DSC resources for Developer Mode, Remote Desktop,
  firewall rules, WSL, Ubuntu 24.04, applications, VS Code extensions,
  Explorer/taskbar/power settings, dark mode, and UAC-related registry changes.

## Typical Order

1. Apply Windows setup with `winget configure`.
2. Restart Windows if required.
3. Launch Ubuntu 24.04 on WSL.
4. Run Ubuntu install scripts in numeric order as needed.
5. Run setup scripts in numeric order as needed.
6. Open a new shell or source `~/.bashrc`.
