# setup-workstation

Bootstrap automation for a Windows 11 host and an Ubuntu 24.04 WSL development
environment.

## Layout

- `winget/`: Windows 11 WinGet DSC configuration.
- `scripts/ubuntu/install/`: Ubuntu/WSL package and tool installers.
- `scripts/ubuntu/setup/`: User environment, shell, Git, and editor setup.
- `docs/`: Repository map, scripting conventions, and project practices.

## Usage

Run the Windows configuration from an elevated Windows terminal:

```powershell
winget configure validate --file .\setup-workstation\winget\w11.yaml
winget configure --file .\setup-workstation\winget\w11.yaml
```

After Ubuntu 24.04 is available in WSL, run the Ubuntu scripts you need in
numeric order:

```bash
bash scripts/ubuntu/install/00-base-packages.sh
bash scripts/ubuntu/setup/03-bashrc-dropin.sh
```

See [docs/repository-map.md](docs/repository-map.md) for the full script list
and recommended order.

## Validation

Validate changed Bash scripts with:

```bash
find scripts/ubuntu -type f -name '*.sh' -print0 | xargs -0 -n1 bash -n
```

Validate the WinGet configuration on Windows with:

```powershell
winget configure validate --file .\setup-workstation\winget\w11.yaml
```

## License

MIT. See [LICENSE](LICENSE).
