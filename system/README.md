# System configuration

This directory contains machine-wide Windows state that does not have a suitable native WinGet/DSC resource.

## WSL 2

`wsl.ps1` manages the WSL platform without selecting or modifying a Linux distribution. It supports three operations:

```powershell
.\system\wsl.ps1 -Operation Get
.\system\wsl.ps1 -Operation Test
.\system\wsl.ps1 -Operation Apply
```

The desired state is:

- the WSL platform is installed;
- no distribution is installed automatically; and
- WSL 2 is the default for distributions installed later.

The apply operation is idempotent. It never converts, unregisters, reinstalls, or resets an existing distribution. Platform installation requests elevation separately, while the default WSL version remains a per-user setting.

If Windows requires a restart after enabling WSL, `scripts/apply.ps1` returns exit code `3010`. Restart Windows and run the check/apply workflow again.

When Windows is itself a virtual machine, the host must expose nested virtualization. Host hypervisor configuration is outside this repository's scope.
