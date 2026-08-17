# Architecture

## Objective

This repository describes a Windows 11 development machine as declaratively as practical. Git records the intended state, WinGet Configuration and DSC enforce resources that have a declarative interface, and PowerShell is reserved for gaps that cannot be represented cleanly through DSC.

The design priorities are:

1. One visible source of truth for each setting.
2. Idempotent operations that are safe to run repeatedly.
3. Least-privilege execution, with elevation requested only by resources that require it.
4. A public repository that never depends on committed secrets.
5. A clear separation between implemented state and future intent.

## Configuration layers

### WinGet Configuration and DSC

`.config/configuration.winget` is the primary desired-state document. Package declarations and DSC-backed settings belong there; a separate package list would create two sources of truth.

The current document contains 23 `Microsoft.WinGet/Package` resources and one elevated `Microsoft.Windows/Registry` resource. Package resources use `useLatest: true`, so applying the configuration may upgrade an already installed package. The human-readable inventory is maintained in [Packages](packages.md), while the configuration document remains the source of truth.

The document uses the WinGet Configuration v3 schema and requires WinGet 1.11 or later. Its package and registry types are native v3 resources; they do not require separately installed PowerShell modules.

### PowerShell helpers

Scripts under `scripts/` provide entry points around WinGet and handle the mapped-drive staging problem. `system/wsl.ps1` manages the WSL platform because no native resource currently expresses the required behavior without also choosing a distribution. PowerShell configuration must expose a reliable test before changing state, avoid resetting existing user data, and remain safe to run repeatedly.

### System and home scopes

Configuration is divided by ownership:

| Scope | Examples |
| --- | --- |
| `system/` | Windows optional features, WSL platform, machine-wide registry or policy state |
| `home/` | PowerShell profile, Git configuration, Terminal settings, Explorer preferences, user dotfiles |

`system/` contains the WSL platform helper. `home/` contains managed PowerShell preferences and a limited set of non-sensitive global Git settings.

### PowerShell profile ownership

The repository owns `home/powershell/profile.ps1`, which is copied to a stable path below `%USERPROFILE%\.config`. PowerShell 7 and Windows PowerShell retain their native profile files; the manager owns only a clearly marked import block inside each file. This allows unmanaged content to coexist with repository state.

Before modifying a pre-existing profile for the first time, the manager creates a `.windows-config.bak` sibling. Malformed or duplicate managed markers are treated as errors instead of being repaired destructively.

### Git configuration ownership

The Git manager owns only keys declared in its `$DesiredSettings` map. It does not rewrite the global configuration file wholesale, so unrelated user settings coexist with repository state. Identity, credentials, signing keys, line endings, and pull/rebase behavior require explicit decisions and remain unmanaged.

## Current boundaries

### Long paths

The configuration sets:

```text
HKLM\SYSTEM\CurrentControlSet\Control\FileSystem
LongPathsEnabled = 1 (DWORD)
```

This is a machine-wide setting and therefore requests elevation. Applications must also opt in to long-path-aware behavior; the registry value alone cannot make every application ignore `MAX_PATH`.

### Developer Mode

Developer Mode is not configured. This means the repository neither enables it nor continually enforces it as disabled. That distinction is intentional.

### Optional Windows features

Full Hyper-V, Windows Sandbox, and Windows Containers are outside the current desired state. Features should be added only when a concrete use case requires them.

## WSL 2 support

`system/wsl.ps1` implements WSL as a system-level feature. It does the following:

- install the WSL platform without choosing a Linux distribution;
- make WSL 2 the default for newly installed distributions;
- preserve existing WSL installations and distribution data;
- report clearly when a restart is required; and
- avoid enabling the full `Microsoft-Hyper-V-All` role solely for WSL 2.

The apply operation is conceptually equivalent to:

```powershell
wsl --install --no-distribution
wsl --set-default-version 2
```

Installation state is tested through `wsl --status`, avoiding localized output parsing. The default version is tested through WSL's per-user `DefaultVersion` state. Platform installation is elevated independently; the default version remains associated with the invoking user.

Distribution selection and Linux user-space configuration belong in a separate layer. The helper never converts, reinstalls, unregisters, or resets an existing distribution. On a Windows guest running under QEMU/KVM or another hypervisor, nested virtualization is an external prerequisite and is not configured by this repository.

## Change criteria

A new resource should answer all of the following before it is merged:

- Is the state appropriate for every machine using this repository?
- Can it be tested without changing the machine?
- Is applying it idempotent?
- Does it require elevation, a restart, or user interaction?
- Could it delete or overwrite user data?
- Does it introduce a secret or machine-specific value?

Prefer a DSC resource when it is trustworthy and expresses the state directly. Use PowerShell only when the desired state cannot be modeled cleanly, and document any irreversible behavior before implementation.

## References

- [WinGet Configuration overview](https://learn.microsoft.com/windows/package-manager/configuration/)
- [WinGet `configure` command](https://learn.microsoft.com/windows/package-manager/winget/configure)
- [WSL command reference](https://learn.microsoft.com/windows/wsl/basic-commands)
- [Maximum path length limitation](https://learn.microsoft.com/windows/win32/fileio/maximum-file-path-limitation)
