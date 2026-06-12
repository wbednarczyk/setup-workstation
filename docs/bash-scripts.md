# Bash Script Layout

Canonical Bash automation lives under `scripts/`.

## Directories

- `scripts/ubuntu/install/`: privileged Ubuntu/WSL installers for packages,
  repositories, and binaries.
- `scripts/ubuntu/setup/`: user environment setup for shell, Git, editors, and
  dotfiles.

## Numbering

- Use dense two-digit prefixes starting at `00`.
- Increment by one for each new script in the same directory.
- Append new scripts at the end by default.
- Renumber only as an intentional organization change.

## Naming

- Use kebab case after the numeric prefix.
- Let the directory describe the phase; avoid repeating `install` or `setup` in
  new canonical filenames.
- Keep header comments aligned with the canonical filename.

## Validation

Validate changed Bash scripts with `bash -n`.

For broad reorganizations, validate the canonical script tree:

```bash
find scripts/ubuntu -type f -name '*.sh' -print0 |
  xargs -0 -n1 bash -n
```
