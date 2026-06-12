# Windows WinGet Configuration

The `winget/` directory configures the Windows 11 host with WinGet DSC.

## Requirements

- Windows 11 Pro is recommended.
- Run from a terminal started as Administrator.
- WinGet must support `winget configure`.

## Commands

From the repository root on Windows:

```powershell
winget configure validate --file .\setup-workstation\winget\w11.yaml
winget configure --file .\setup-workstation\winget\w11.yaml
```

Some resources require restart. After restarting, run `winget configure` again
so dependent steps can complete.

## Resource Conventions

- Use `description` directives for every resource.
- Use `allowPrerelease: true` where required by Microsoft developer resources.
- Use `securityContext: elevated` for machine-level changes.
- Use `securityContext: current` for user-level Explorer settings.
- Use `dependsOn` for resources that require earlier settings or packages.
- Custom `PSDscResources/Script` resources must provide `GetScript`,
  `TestScript`, and `SetScript`.
- Keep `TestScript` idempotent and tolerant of command failures.

## Current Coverage

The manifest configures:

- Developer Mode.
- Remote Desktop and TCP/UDP firewall rules.
- RDP Network Level Authentication registry behavior.
- WSL optional features.
- WSL package installation.
- WSL default version 2.
- Ubuntu 24.04 installation under WSL.
- Microsoft Teams, Windows Terminal, PowerToys, 7-Zip, Firefox, Obsidian, and
  Visual Studio Code.
- VS Code extensions for Remote WSL, ChatGPT, OpenTofu, markdownlint, and
  GitLens.
- Explorer file extension and hidden file visibility.
- Seconds in the system tray clock.
- Taskbar alignment and button visibility.
- Battery and AC display/sleep timeout values.
- Dark mode.
- UAC prompt behavior and `EnableLUA=0` registry setting.

## Notes

- The manifest includes Polish output text in the UAC `SetScript`; preserve it
  unless intentionally standardizing language.
- The WSL default-version check supports English and Polish `wsl --status`
  output.
- The file declares DSC schema version `0.2` and configuration version `0.2.0`.
