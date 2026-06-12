# Project Practises

This repository is maintained as a practical workstation bootstrap kit. Prefer
clear, repeatable automation over broad abstractions.

## Scope

- Keep the project focused on workstation setup.
- Put Ubuntu/WSL installers in `install-scripts/`.
- Put user environment and dotfile setup in `setup-scripts/`.
- Put Windows host setup in `winget/`.
- Put repository guidance and explanations in `docs/`.
- Avoid adding framework or build tooling unless it solves a concrete
  repository problem.

## Adding Automation

- Add a new numbered script when the behavior is independently runnable.
- Extend an existing script only when the change is part of that script's
  current responsibility.
- Preserve the numeric flow so a user can run scripts in order.
- Make scripts safe to rerun.
- State prerequisites in comments or docs when a script depends on another
  script.
- Keep network downloads explicit and from official project URLs where
  possible.
- Verify installed commands with `command -v` and a version or status command.

## Editing Existing Scripts

- Read the whole target script before changing it.
- Preserve its logging style, root handling, and user ownership behavior.
- Do not silently change generated file names, drop-in order, or managed config
  paths.
- Do not broaden privileged writes beyond the script's existing purpose.
- Avoid replacing an append-only user preference with an overwrite.
- Keep generated heredoc content self-contained and easy to audit.

## Documentation

- Keep `AGENTS.md` lean and link deeper references from `docs/`.
- Document conventions that are discovered from the repository, not aspirational
  rules that existing code does not follow.
- Update `docs/repository-map.md` when files or directories are added.
- Update `docs/script-conventions.md` when shell patterns change.
- Update `docs/windows-winget.md` when `winget/w11.yaml` changes meaningfully.
- Prefer concise Markdown with headings and flat lists.

## Validation

- Run `bash -n` for every changed shell script.
- For broad shell convention changes, run `bash -n` across all scripts.
- Validate WinGet YAML with `winget configure validate` when editing
  `winget/w11.yaml`.
- Do not run installer scripts as a substitute for syntax validation unless the
  user explicitly wants system changes performed.
- Note when validation was skipped because it requires Windows, network access,
  sudo, or a restart.

## Safety

- Treat existing untracked files as user work unless told otherwise.
- Do not remove or revert unrelated changes.
- Be careful with scripts that write to:
  - `/etc/sudoers.d`
  - `/etc/wsl.conf`
  - `/etc/apt`
  - `/usr/local/bin`
  - user dotfiles under `$HOME`
- Validate privileged config after writing it, such as using `visudo` for
  sudoers files.
- Back up user-authored files before appending managed blocks.

## User Experience

- Scripts should print what they are doing.
- Error messages should name the missing command, unsupported platform, or file
  path.
- Finish with a concrete next step when the user must reload a shell, open a new
  terminal, restart WSL, restart Windows, or rerun a command.
- Avoid noisy output where a concise status line is enough.

## Versioning

- Pin versions only when stability or compatibility requires it.
- If a script installs latest, document that behavior and make the target
  architecture explicit.
- If a script pins a major version, allow a clear argument or variable override
  when practical.
- Keep package source setup idempotent, including keyrings and repository files.
