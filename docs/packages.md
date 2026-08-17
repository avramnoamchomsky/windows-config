# Packages

`.config/configuration.winget` is the source of truth for installed software. This catalog provides a compact review view of the package resources managed by the repository. Every package uses the public `winget` source and `useLatest: true`.

## Core development tools

| Package | WinGet ID | Purpose |
| --- | --- | --- |
| Git | `Git.Git` | Version control |
| PowerShell 7 | `Microsoft.PowerShell` | Modern PowerShell runtime |
| Visual Studio Code | `Microsoft.VisualStudioCode` | Code editor |
| Windows Terminal | `Microsoft.WindowsTerminal` | Terminal application |

## Desktop applications

| Package | WinGet ID | Purpose |
| --- | --- | --- |
| 7-Zip | `7zip.7zip` | Archive management |
| Everything | `voidtools.Everything` | Fast file-name search |
| Google Chrome | `Google.Chrome` | Web browser |
| Tencent QQ | `Tencent.QQ.NT` | Messaging |
| Tencent WeChat | `Tencent.WeChat.Universal` | Messaging |
| mpv | `shinchiro.mpv` | Media player |
| DiskGenius | `Eassos.DiskGenius` | Disk and partition management |
| CrystalDiskMark Aoi Edition | `CrystalDewWorld.CrystalDiskMark.AoiEdition` | Storage benchmark |

## Command-line tools

| Package | WinGet ID | Purpose |
| --- | --- | --- |
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
