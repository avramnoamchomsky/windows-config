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

`check.ps1` returns `1` when WinGet/DSC, the PowerShell profile, or WSL is out of state. `apply.ps1` returns `3010` when Windows must be restarted to finish enabling WSL; other failures return a nonzero code or a terminating PowerShell error.

The check/apply workflow also manages the current user's PowerShell 7 and Windows PowerShell all-hosts profiles. Existing content outside the marked `windows-config` block is preserved.

For optional validator diagnostics without testing live state, run WinGet directly:

```powershell
winget configure validate -f .\.config\configuration.winget
```

This command is not an automated gate because current builds may emit resource-discovery warnings for native v3 resources; see [Configuration validation warnings](#configuration-validation-warnings). `check.ps1` instead runs `winget configure test` and `system/wsl.ps1 -Operation Test`, which evaluate live state.

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

`bootstrap.ps1` first verifies Windows 11, WinGet 1.11 or later, and the presence of `wsl.exe`. If the repository is not already at the selected local path, it calls `copy-local.ps1 -Clean` and applies the configuration from the staged copy. If the paths already match, it applies in place.

```powershell
# Default local path: %USERPROFILE%\projects\windows-config
.\scripts\bootstrap.ps1

# Explicit local execution path
.\scripts\bootstrap.ps1 -LocalRepo 'C:\WindowsConfigStage'
```

Because bootstrap stages and applies immediately, use the explicit copy/check/apply workflow when you want to inspect conformance before applying.

## PowerShell profile workflow

The main scripts manage the profile automatically. To inspect or operate it separately:

```powershell
.\home\powershell\manage-profile.ps1 -Operation Get
.\home\powershell\manage-profile.ps1 -Operation Test
.\home\powershell\manage-profile.ps1 -Operation Apply
```

Changes to `home/powershell/profile.ps1` take effect after the next apply and in newly started PowerShell sessions. The deployed copy lives at `%USERPROFILE%\.config\windows-config\powershell\profile.ps1`; native profile files contain only a marked loader plus any pre-existing unmanaged content.

If a native profile existed before adoption, its one-time backup has the suffix `.windows-config.bak`. Restore that file manually only after reviewing any profile changes made since the backup.

## First-run behavior

WinGet may report that its Desired State Configuration package is missing and install the DSC v3 processor during the first configuration run. Allow that prerequisite installation to finish, then rerun the command if WinGet asks for it.

The bootstrap script does not install WinGet or explicitly preinstall DSC. WinGet Configuration v3 requires WinGet 1.11 or later; update App Installer if the prerequisite check rejects the installed version.

## Troubleshooting

### Elevated resource cannot find a network path

Symptoms may include error `-2147023693` or a message that the network path is unavailable. Stage the repository to a local fixed drive and rerun it there. Do not change UAC mapped-drive behavior merely to make this repository work; local staging keeps the privilege boundary explicit.

Microsoft explains why [mapped drives can be unavailable from an elevated prompt](https://learn.microsoft.com/troubleshoot/windows-client/networking/mapped-drives-not-available-from-elevated-command).

### Configuration validation warnings

The current `Microsoft.WinGet/Package` and `Microsoft.Windows/Registry` resources are native DSC v3 resources and must not declare unrelated PowerShell modules. On the tested WinGet 1.29 build, `winget configure validate` warns that these native resources have no module and are not publicly available, then may return a failure code even though `winget configure` can resolve and apply them.

For that reason, the standalone validator is informational and is not an automated gate. `check.ps1` uses `winget configure test`, while `apply.ps1` uses `winget configure`; both commands parse the document and fail safely if it is invalid. Do not silence the warnings by inventing module metadata.

### Long paths still fail in one application

The repository enables the system registry setting, but a Windows application also has to declare itself long-path aware. A failure isolated to one application does not necessarily mean the DSC resource is out of state. See Microsoft's [maximum path length documentation](https://learn.microsoft.com/windows/win32/fileio/maximum-file-path-limitation).

### WSL requires a restart

If WSL installation succeeds but `wsl --status` is not ready, `apply.ps1` returns `3010`. Restart Windows and run `check.ps1` followed by `apply.ps1` again.

### WSL commands fail in a virtual machine

Check `wsl --status` and `systeminfo`, then verify that the host exposes nested virtualization before diagnosing the failure as a Windows configuration issue. The repository does not configure the host hypervisor.
