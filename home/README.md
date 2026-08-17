# Home configuration

This directory contains per-user configuration and dotfiles. Machine-wide features, services, and registry state belong under `system/` instead.

## PowerShell profile

`powershell/profile.ps1` is the repository-managed, cross-host PowerShell profile. It currently configures:

- VS Code as `EDITOR` and `VISUAL`;
- Windows edit mode and duplicate-free history through PSReadLine;
- history-based command prediction when supported;
- list-style prediction when supported;
- menu completion on Tab; and
- `Test-WindowsConfig` and `Update-WindowsConfig` helper functions.

PSReadLine settings are applied only in `ConsoleHost` and are feature-detected for compatibility with both PowerShell 7 and Windows PowerShell 5.1. Unsupported options are skipped without preventing the shell from starting.

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

## Git configuration

`git/manage-git.ps1` manages a small set of non-sensitive global settings:

| Key | Value | Purpose |
| --- | --- | --- |
| `init.defaultBranch` | `main` | Use `main` for new repositories |
| `fetch.prune` | `true` | Remove stale remote-tracking branches during fetch |
| `push.autoSetupRemote` | `true` | Set the upstream automatically on the first push |
| `core.longpaths` | `true` | Allow Git for Windows to use long paths |
| `core.editor` | `code --wait` | Use VS Code for Git editing workflows |

The manager supports the same operations as the profile manager:

```powershell
.\home\git\manage-git.ps1 -Operation Get
.\home\git\manage-git.ps1 -Operation Test
.\home\git\manage-git.ps1 -Operation Apply
```

It owns only the keys listed above and preserves every other global Git setting. User identity, credential helpers, signing keys, line-ending policy, and pull/rebase strategy are intentionally unmanaged.

To stop managing a key, remove it from `$DesiredSettings` and decide explicitly whether to leave its current global value or remove it with:

```powershell
git config --global --unset-all <key>
```

## Microsoft Pinyin

`input-method/set-xiaohe-double-pinyin.ps1` configures the current user's first custom double-pinyin scheme as Xiaohe. Run it manually only after the Microsoft Chinese input method has been installed and enabled:

```powershell
.\home\input-method\set-xiaohe-double-pinyin.ps1
```

The script writes and verifies this user-scoped registry value:

```text
HKCU\Software\Microsoft\InputMethod\Settings\CHS
UserDefinedDoublePinyinScheme0 = 小鹤双拼*2*^*iuvdjhcwfg^xmlnpbksqszxkrltvyovt (REG_SZ)
```

Running the script again is safe. It exits without writing when the value is already correct. This optional step is not called by the main apply or check workflows because the input method is an external prerequisite.

## Future areas

Candidate additions include Windows Terminal settings, VS Code settings and extensions, Explorer preferences, and application-specific user settings. A setting should only be added after its desired value, merge behavior, and recovery path are known. Secrets and machine-specific credentials must remain outside the repository.
