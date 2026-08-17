# Operations

## Safety model

Run this repository from a normal PowerShell session. WinGet will request UAC elevation for the registry resource that needs machine-wide access. Before applying, review `.config/configuration.winget` and confirm that every package and DSC resource is expected.

The local execution copy is disposable. The canonical Git working tree is the only place where edits and commits should be made.

## Local-drive workflow

For a repository already located on a local fixed drive:

```powershell
cd C:\path\to\windows-config

# Check current conformance without applying changes.
.\scripts\check.ps1

# Apply desired state.
.\scripts\apply.ps1

# Confirm conformance afterward.
.\scripts\check.ps1
```

The scripts return WinGet's exit code, so a nonzero exit code can be used to fail a larger automation workflow.

To validate only the configuration document's structure, run WinGet directly:

```powershell
winget configure validate -f .\.config\configuration.winget
```

`check.ps1` intentionally runs `winget configure test`, which evaluates the live machine rather than only validating the file.

## Mapped-drive workflow

UAC elevation can create a logon context that does not share drive-letter mappings with the normal user session. An elevated DSC resource may therefore fail when the configuration is launched from a mapped drive, even though non-elevated package resources work.

Keep editing on the canonical mapped-drive checkout, but copy the repository to a local fixed drive for execution:

```powershell
cd Y:\path\to\windows-config
.\scripts\copy-local.ps1 -Clean

cd "$env:USERPROFILE\projects\windows-config"
.\scripts\check.ps1
.\scripts\apply.ps1
.\scripts\check.ps1
```

The copy includes hidden entries such as `.config` and `.git`. Without `-Clean`, existing files are overwritten but stale destination-only files remain. With `-Clean`, the entire destination is removed first and becomes an exact fresh copy.

> **Warning:** `-Clean` deletes the destination tree. The script refuses to use the source itself as the destination, but the destination must still be treated as disposable.

To use a different local destination:

```powershell
.\scripts\copy-local.ps1 `
    -Destination 'C:\WindowsConfigStage' `
    -Clean
```

## Bootstrap shortcut

`bootstrap.ps1` verifies that WinGet is available and prints its version. If the repository is not already at the selected local path, it calls `copy-local.ps1 -Clean` and applies the configuration from the staged copy. If the paths already match, it applies in place.

```powershell
# Default local path: %USERPROFILE%\projects\windows-config
.\scripts\bootstrap.ps1

# Explicit local execution path
.\scripts\bootstrap.ps1 -LocalRepo 'C:\WindowsConfigStage'
```

Because bootstrap stages and applies immediately, use the explicit copy/check/apply workflow when you want to inspect conformance before applying.

## First-run behavior

WinGet may report that its Desired State Configuration package is missing and install the DSC v3 processor during the first configuration run. Allow that prerequisite installation to finish, then rerun the command if WinGet asks for it.

The current bootstrap script verifies WinGet but does not install WinGet or explicitly preinstall DSC. On supported Windows 11 systems, WinGet is delivered through App Installer; update App Installer if `winget configure` is unavailable.

## Troubleshooting

### Elevated resource cannot find a network path

Symptoms may include error `-2147023693` or a message that the network path is unavailable. Stage the repository to a local fixed drive and rerun it there. Do not change UAC mapped-drive behavior merely to make this repository work; local staging keeps the privilege boundary explicit.

Microsoft explains why [mapped drives can be unavailable from an elevated prompt](https://learn.microsoft.com/troubleshoot/windows-client/networking/mapped-drives-not-available-from-elevated-command).

### Configuration validation warnings

WinGet may warn that a module was not specified or that a configuration unit is not publicly available. Warnings are not necessarily failures: use the process exit code and the final resource results to determine whether validation, testing, or application succeeded. Investigate new warnings before suppressing them.

### Long paths still fail in one application

The repository enables the system registry setting, but a Windows application also has to declare itself long-path aware. A failure isolated to one application does not necessarily mean the DSC resource is out of state. See Microsoft's [maximum path length documentation](https://learn.microsoft.com/windows/win32/fileio/maximum-file-path-limitation).

### WSL commands fail in a virtual machine

WSL is not currently configured by this repository. If testing future WSL work inside a VM, check `wsl --status` and `systeminfo`, then verify that the host exposes nested virtualization before diagnosing the failure as a Windows configuration issue.
