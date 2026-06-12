# Windows 11 Setup with WinGet Configuration

This directory contains the initial Windows 11 setup configuration: `w11.yaml`.

## Requirements

- Windows 11 Pro (recommended)
- WinGet with `configure` support
- Terminal started as Administrator

## Usage

Run from the repository root:

```powershell
winget configure validate --file .\setup-workstation\winget\w11.yaml
winget configure --file .\setup-workstation\winget\w11.yaml
```

## Notes

- The configuration is idempotent, so it can be run multiple times safely.
- Some changes (for example UAC/WSL/features) may require a restart.
- After restart, run `winget configure` again to complete dependent steps.
