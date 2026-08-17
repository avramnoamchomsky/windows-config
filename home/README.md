# Home configuration

This directory contains per-user configuration and dotfiles. Machine-wide features, services, and registry state belong under `system/` instead.

## PowerShell profile

`powershell/profile.ps1` is the repository-managed, cross-host PowerShell profile. It is intentionally neutral at first; portable, non-sensitive preferences can be added there as they are chosen.

`powershell/manage-profile.ps1` supports three operations:

```powershell
.\home\powershell\manage-profile.ps1 -Operation Get
.\home\powershell\manage-profile.ps1 -Operation Test
.\home\powershell\manage-profile.ps1 -Operation Apply
```

Apply performs the following actions:

1. Copies the managed profile to `%USERPROFILE%\.config\windows-config\powershell\profile.ps1`.
2. Adds a marked loader block to the current user's PowerShell 7 all-hosts profile.
3. Adds the same loader to the current user's Windows PowerShell all-hosts profile.
4. Preserves all content outside the marked block.

The managed target profiles are:

```text
%USERPROFILE%\Documents\PowerShell\profile.ps1
%USERPROFILE%\Documents\WindowsPowerShell\profile.ps1
```

Windows may redirect the Documents folder; the script resolves its actual location rather than assuming the paths above literally.

If a target profile already exists without a managed block, it is copied once to:

```text
<profile path>.windows-config.bak
```

Subsequent applies update only the content between the `windows-config` markers. Unmatched or duplicate markers cause a terminating error rather than risking profile corruption.

The main `scripts/check.ps1` and `scripts/apply.ps1` entry points include this profile state automatically.

## Future areas

Candidate additions include Git configuration, Windows Terminal settings, Explorer preferences, and application-specific user settings. A setting should only be added after its desired value, merge behavior, and recovery path are known. Secrets and machine-specific credentials must remain outside the repository.
