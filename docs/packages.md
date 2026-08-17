# Packages

`.config/configuration.winget` is the source of truth for installed software. This catalog provides a compact review view of the package resources managed by the repository. Every package uses the public `winget` source. Packages use `useLatest: true` unless an exception is documented below.

## Core development tools

| Package | WinGet ID | Purpose |
| --- | --- | --- |
| Git | `Git.Git` | Version control |
| PowerShell 7 | `Microsoft.PowerShell` | Modern PowerShell runtime |
| Python 3.14 | `Python.Python.3.14` | Python runtime and standard tooling |
| Visual Studio Code | `Microsoft.VisualStudioCode` | Code editor |
| Windows Terminal | `Microsoft.WindowsTerminal` | Terminal application |
| MSYS2 | `MSYS2.MSYS2` | Unix-like environment and `pacman` package manager |

MSYS2 uses `useLatest: false` because its WinGet manifest has `UpgradeBehavior: deny`. WinGet ensures that the base environment is installed; update the environment and install toolchains with `pacman` inside MSYS2.

## Desktop applications

| Package | WinGet ID | Purpose |
| --- | --- | --- |
| 7-Zip | `7zip.7zip` | Archive management |
| Everything | `voidtools.Everything` | Fast file-name search |
| Bulk Crap Uninstaller | `Klocman.BulkCrapUninstaller` | Application removal and leftover cleanup |
| Google Chrome | `Google.Chrome` | Web browser |
| Tencent QQ | `Tencent.QQ.NT` | Messaging |
| Tencent WeChat | `Tencent.WeChat.Universal` | Messaging |
| mpv | `shinchiro.mpv` | Media player |
| DiskGenius | `Eassos.DiskGenius` | Disk and partition management |
| CrystalDiskMark Aoi Edition | `CrystalDewWorld.CrystalDiskMark.AoiEdition` | Storage benchmark |

## Command-line tools

| Package | WinGet ID | Purpose |
| --- | --- | --- |
| btop | `aristocratos.btop4win` | Interactive system and process monitor |
| ripgrep | `BurntSushi.ripgrep.MSVC` | Recursive text search |
| fd | `sharkdp.fd` | File-system search |
| bat | `sharkdp.bat` | Syntax-aware file viewer |
| fzf | `junegunn.fzf` | Fuzzy finder |
| zoxide | `ajeetdsouza.zoxide` | Directory navigation |
| eza | `eza-community.eza` | Modern directory listing |
| jq | `jqlang.jq` | JSON processor |
| yq | `MikeFarah.yq` | YAML processor |
| Fastfetch | `Fastfetch-cli.Fastfetch` | System information summary |
| Starship | `Starship.Starship` | Cross-shell prompt engine |

## Deliberately excluded

The following packages were considered but are intentionally not managed: PowerToys, SumatraPDF, VLC, ShareX, and GitHub CLI.

Starship and zoxide are installed but not initialized by the managed PowerShell profile. Installation and shell behavior are separate decisions so applying the package catalog does not unexpectedly replace the user's prompt or navigation commands.
