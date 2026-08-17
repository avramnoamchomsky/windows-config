# windows-config

[English](README.md) | [简体中文](README.zh-CN.md)

Declarative configuration for a personal Windows 11 development environment.

The repository combines [WinGet Configuration](https://learn.microsoft.com/windows/package-manager/configuration/) with DSC resources and small, idempotent PowerShell helpers. The goal is a machine definition that is reviewable, repeatable, and safe to keep in a public Git repository.

## Current state

The configuration currently manages:

| Area | Desired state | Status |
| --- | --- | --- |
| Packages | Git, PowerShell 7, Visual Studio Code, and Windows Terminal are installed from WinGet and kept current | Implemented |
| System | Win32 long-path support is enabled through `LongPathsEnabled` | Implemented |
| WSL | WSL 2 platform installed without selecting a Linux distribution | Planned |
| Developer Mode | Left unmanaged | Intentional |
| Hyper-V, Sandbox, Containers | Not enabled by this repository | Intentional |

The complete implemented state is visible in [`.config/configuration.winget`](.config/configuration.winget). Review that file before applying it: the apply script accepts the WinGet configuration agreement non-interactively, and one resource requests elevation to write to `HKLM`.

## Requirements

- Windows 11
- WinGet with `winget configure` support (WinGet 1.6.2631 or later)
- PowerShell
- Network access for packages and DSC resources that are not already cached

Run the scripts from a normal, non-elevated PowerShell session. WinGet can request elevation for the individual system resource that needs it.

## Quick start

Clone the repository to a local drive, inspect the desired state, and then test and apply it:

```powershell
git clone https://github.com/avramnoamchomsky/windows-config.git
cd .\windows-config

Get-Content .\.config\configuration.winget
.\scripts\check.ps1
.\scripts\apply.ps1
.\scripts\check.ps1
```

`check.ps1` runs `winget configure test`; it checks conformance but does not change the machine. `apply.ps1` applies the configuration and returns WinGet's exit code.

## Repositories on mapped drives

An elevated DSC resource may be unable to access a drive letter mapped in the normal user session. If the canonical working tree is on a mapped or network drive, stage an execution copy on the local system drive first:

```powershell
.\scripts\copy-local.ps1 -Clean
cd "$env:USERPROFILE\projects\windows-config"
.\scripts\check.ps1
.\scripts\apply.ps1
.\scripts\check.ps1
```

`-Clean` removes the existing destination before copying, so do not keep uncommitted work in the local execution copy. The mapped-drive working tree remains the source of truth for editing and Git operations.

For a one-command stage-and-apply flow, run:

```powershell
.\scripts\bootstrap.ps1
```

By default, `bootstrap.ps1` replaces `%USERPROFILE%\projects\windows-config` with a fresh copy when invoked elsewhere, then applies from that local path. A different destination can be supplied with `-LocalRepo`.

See [Operations](docs/operations.md) for the full workflow and troubleshooting notes.

## Repository layout

```text
windows-config/
├── .config/
│   └── configuration.winget   # WinGet/DSC desired state
├── docs/
│   ├── architecture.md        # design decisions and scope
│   └── operations.md          # apply, check, and staging workflows
├── scripts/
│   ├── apply.ps1              # apply desired state
│   ├── bootstrap.ps1          # stage locally when needed, then apply
│   ├── check.ps1              # test current state for conformance
│   └── copy-local.ps1         # create/update a local execution copy
├── .gitignore
├── LICENSE
├── README.md
└── README.zh-CN.md
```

Machine-wide settings belong conceptually under `system/`; per-user settings and dotfiles belong under `home/`. Those areas will be added when they contain implemented configuration. See [Architecture](docs/architecture.md) for the boundaries and planned WSL work.

## Script reference

| Script | Behavior |
| --- | --- |
| `scripts/check.ps1` | Tests the machine against `.config/configuration.winget` |
| `scripts/apply.ps1` | Applies the WinGet configuration and accepts its agreement |
| `scripts/copy-local.ps1` | Copies all repository content, including `.config` and `.git`, to a local path; `-Clean` makes it an exact replacement |
| `scripts/bootstrap.ps1` | Verifies WinGet, creates a clean local execution copy when necessary, and applies it |

## Security and secrets

This is a public repository. Do not commit credentials, tokens, private keys, machine-specific secrets, or exported configuration containing sensitive data. Local overrides and a future `secrets/` directory are excluded by [`.gitignore`](.gitignore).

Review every package and DSC resource before applying changes. Microsoft also documents a [recommended trust review for WinGet Configuration files](https://learn.microsoft.com/windows/package-manager/configuration/check).

## License

[MIT](LICENSE)
