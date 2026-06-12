# Repository Map

This repository contains workstation bootstrap automation for a Windows 11 host
and an Ubuntu WSL environment.

## Root

- `README.md`: Repository overview, usage, validation, and license.
- `MAINTAINERS.md`: Repository maintainers.
- `LICENSE`: MIT license.
- `AGENTS.md`: Contributor and agent instructions for this repository.

## `scripts/`

Primary automation lives under `scripts/`.

- `scripts/ubuntu/install/`: Ubuntu/WSL installers that provision system
  packages and developer tools.
- `scripts/ubuntu/setup/`: User environment and dotfile setup scripts.

## `scripts/ubuntu/install/`

- `00-base-packages.sh`: Installs common Ubuntu packages:
  certificates, curl/wget, build tools, shell utilities, archive tools, `jq`,
  `yq`, `fzf`, `ripgrep`, `direnv`, and network tools.
- `01-docker-wsl.sh`: Installs Docker Engine inside Ubuntu on WSL 2,
  enables systemd if required, configures Docker's apt repository, installs a
  selected Docker major version when available, starts Docker, and adds the
  original user to the `docker` group.
- `02-starship.sh`: Installs Starship into `/usr/local/bin` using the
  official installer.
- `03-nix.sh`: Installs Nix using the official multi-user daemon
  installer and writes a Bash drop-in for Nix profile loading.
- `04-kind.sh`: Installs the latest x64 Linux kind binary into
  `/usr/local/bin`.
- `05-gh-cli.sh`: Installs GitHub CLI from GitHub's official apt
  repository and verifies the `gh` command.
- `06-radicle.sh`: Installs the Radicle toolchain from Radicle's
  official apt repository and verifies the `rad` command.
- `07-radboard.sh`: Installs Radboard from the official Debian package,
  installing Radicle first with `06-radicle.sh` when `rad` is missing,
  adds a WSL rendering wrapper, and verifies the `radboard` command.
- `08-git-cliff.sh`: Installs the latest x64 Linux git-cliff binary
  into `/usr/local/bin` and verifies the `git-cliff` command.
- `09-repoctx.sh`: Installs the latest x64 Linux repoctx binary into
  `/usr/local/bin`, verifies the release checksum, and verifies the `repoctx`
  command.

## `scripts/ubuntu/setup/`

Setup scripts configure the user's shell, editor, Git defaults, and dotfiles.

- `00-sudo-passwordless.sh`: Writes and validates a sudoers drop-in for
  passwordless sudo for the invoking non-root user.
- `01-git-config.sh`: Adds Git aliases, default editor, and GitHub SSH
  `insteadOf` configuration without overwriting existing differing values.
- `02-gitignore-global.sh`: Writes `~/.gitignore_global` and configures Git to
  use it.
- `03-bashrc-dropin.sh`: Creates `~/.bashrc.d` and appends a managed
  include block to `~/.bashrc`, backing up the original file first.
- `04-git-branch-prompt.sh`: Writes a self-contained Bash prompt drop-in
  with Git branch and repository status.
- `05-editor.sh`: Writes `~/.bashrc.d/00-editor.sh` to set
  `EDITOR`, `VISUAL`, and `PAGER`.
- `06-starship.sh`: Writes `~/.config/starship.toml` and
  `~/.bashrc.d/90-starship.sh`.
- `07-nix-direnv.sh`: Writes `~/.bashrc.d/99-direnv.sh` and
  enables Nix flakes in `~/.config/nix/nix.conf` if absent.
- `08-vimrc.sh`: Writes a managed `~/.vimrc` with basic editor settings.

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
4. Run `scripts/ubuntu/install/` scripts in numeric order as needed.
5. Run `scripts/ubuntu/setup/` scripts in numeric order as needed.
6. Open a new shell or source `~/.bashrc`.
