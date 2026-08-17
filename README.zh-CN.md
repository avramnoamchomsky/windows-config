# windows-config

[English](README.md) | [简体中文](README.zh-CN.md)

个人 Windows 11 开发环境的声明式配置。

本仓库结合了 [WinGet 配置](https://learn.microsoft.com/zh-cn/windows/package-manager/configuration/)与 DSC 资源，并辅以少量幂等的 PowerShell 辅助脚本。目标是构建一份可审查、可重复执行，并且适合安全地存放在公开 Git 仓库中的计算机配置定义。

## 当前状态

本配置目前管理以下内容：

| 范围 | 目标状态 | 状态 |
| --- | --- | --- |
| 软件包 | 通过 WinGet 安装 Git、PowerShell 7、Visual Studio Code 和 Windows Terminal，并保持最新版本 | 已实现 |
| 系统 | 通过 `LongPathsEnabled` 启用 Win32 长路径支持 | 已实现 |
| WSL | 安装 WSL 2 平台，但不选择或修改 Linux 发行版 | 已实现 |
| 开发人员模式 | 不由本仓库管理 | 有意如此 |
| Hyper-V、Sandbox、Containers | 不由本仓库启用 | 有意如此 |

所有已实现的目标状态均可在 [`.config/configuration.winget`](.config/configuration.winget) 中查看。应用配置前请先审查该文件：应用脚本会以非交互方式接受 WinGet 配置协议，并且其中一个资源会请求提升权限以写入 `HKLM`。

## 环境要求

- Windows 11
- WinGet 1.11 或更高版本，并支持 DSC v3 配置
- PowerShell
- 可访问网络，以获取尚未缓存的软件包和 DSC 资源

请从普通的非管理员 PowerShell 会话运行这些脚本。WinGet 会在需要时仅为相应的系统资源请求提升权限。

## 快速开始

将仓库克隆到本地磁盘，审查目标状态，然后进行检查并应用配置：

```powershell
git clone https://github.com/avramnoamchomsky/windows-config.git
cd .\windows-config

Get-Content .\.config\configuration.winget
.\scripts\check.ps1
.\scripts\apply.ps1
.\scripts\check.ps1
```

`check.ps1` 会验证配置文档，并检查 WinGet/DSC 和 WSL 状态，但不会修改计算机。`apply.ps1` 会验证并应用这两个配置层。

如果启用 WSL 后需要重新启动，`apply.ps1` 会返回退出代码 `3010`。请重新启动 Windows，然后再次运行检查和应用流程。

## 位于映射驱动器上的仓库

提升权限后的 DSC 资源可能无法访问普通用户会话中映射的驱动器盘符。如果作为配置源的工作树位于映射驱动器或网络驱动器上，请先将用于执行的副本暂存到本地系统盘：

```powershell
.\scripts\copy-local.ps1 -Clean
cd "$env:USERPROFILE\projects\windows-config"
.\scripts\check.ps1
.\scripts\apply.ps1
.\scripts\check.ps1
```

`-Clean` 会先删除现有目标目录再进行复制，因此不要在本地执行副本中保留未提交的工作。映射驱动器上的工作树仍是编辑和执行 Git 操作的唯一配置源。

如需通过一条命令完成暂存和应用，请运行：

```powershell
.\scripts\bootstrap.ps1
```

默认情况下，如果从其他位置调用 `bootstrap.ps1`，它会使用全新副本替换 `%USERPROFILE%\projects\windows-config`，然后从该本地路径应用配置。可以通过 `-LocalRepo` 指定其他目标路径。

完整工作流程和故障排除说明请参阅[操作指南](docs/operations.md)。

## 仓库结构

```text
windows-config/
├── .config/
│   └── configuration.winget   # WinGet/DSC 目标状态
├── docs/
│   ├── architecture.md        # 设计决策与范围
│   └── operations.md          # 应用、检查及暂存工作流程
├── home/
│   └── README.md              # 未来用户级状态的管理原则
├── scripts/
│   ├── apply.ps1              # 应用目标状态
│   ├── assert-prerequisites.ps1 # 检查 Windows、WinGet 和 WSL CLI
│   ├── bootstrap.ps1          # 必要时暂存到本地，然后应用
│   ├── check.ps1              # 检查当前状态是否符合配置
│   └── copy-local.ps1         # 创建或更新本地执行副本
├── system/
│   ├── README.md              # 计算机级配置说明
│   └── wsl.ps1                # 幂等的 WSL 2 平台状态
├── .gitignore
├── LICENSE
├── README.md
└── README.zh-CN.md
```

计算机范围的设置归入 `system/`；用户级设置和 dotfiles 则归入 `home/`。关于各层的职责边界，请参阅[架构说明](docs/architecture.md)。

## 脚本参考

| 脚本 | 行为 |
| --- | --- |
| `scripts/assert-prerequisites.ps1` | 要求 Windows 11、WinGet 1.11 或更高版本，以及 Windows WSL CLI |
| `scripts/check.ps1` | 验证 WinGet 文档，并检查 WinGet/DSC 和 WSL 状态 |
| `scripts/apply.ps1` | 验证并应用 WinGet/DSC 和 WSL 状态 |
| `scripts/copy-local.ps1` | 将包括 `.config` 和 `.git` 在内的所有仓库内容复制到本地路径；使用 `-Clean` 时会完整替换目标目录 |
| `scripts/bootstrap.ps1` | 检查所有环境要求，必要时创建干净的本地执行副本，然后应用配置 |

## 安全与机密信息

这是一个公开仓库。请勿提交凭据、令牌、私钥、计算机专用机密信息，或包含敏感数据的导出配置。本地覆盖文件以及将来可能使用的 `secrets/` 目录已通过 [`.gitignore`](.gitignore) 排除。

应用变更前，请审查每个软件包和 DSC 资源。Microsoft 也提供了 [WinGet 配置文件可信性检查指南](https://learn.microsoft.com/zh-cn/windows/package-manager/configuration/check)。

## 许可证

[MIT](LICENSE)
