[CmdletBinding()]
param(
    [ValidateSet("Get", "Test", "Apply")]
    [string]$Operation = "Test"
)

$ErrorActionPreference = "Stop"

$LxssRegistryPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Lxss"
$DefaultVersionValue = "DefaultVersion"

function Get-WslCommand {
    Get-Command `
        -Name "wsl.exe" `
        -CommandType Application `
        -ErrorAction SilentlyContinue |
        Select-Object -First 1
}

function Test-IsAdministrator {
    $Identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $Principal = [Security.Principal.WindowsPrincipal]::new($Identity)

    $Principal.IsInRole(
        [Security.Principal.WindowsBuiltInRole]::Administrator
    )
}

function Get-WslState {
    $WslCommand = Get-WslCommand
    $Installed = $false

    if ($null -ne $WslCommand) {
        & $WslCommand.Source --status *> $null
        $Installed = $LASTEXITCODE -eq 0
    }

    # Current WSL defaults to version 2 when this value does not exist.
    $DefaultVersion = 2

    if (Test-Path -LiteralPath $LxssRegistryPath) {
        $ConfiguredVersion = Get-ItemPropertyValue `
            -LiteralPath $LxssRegistryPath `
            -Name $DefaultVersionValue `
            -ErrorAction SilentlyContinue

        if ($null -ne $ConfiguredVersion) {
            $DefaultVersion = [int]$ConfiguredVersion
        }
    }

    [pscustomobject]@{
        CommandAvailable = $null -ne $WslCommand
        Installed = $Installed
        DefaultVersion = $DefaultVersion
        InDesiredState = $Installed -and ($DefaultVersion -eq 2)
        RestartRequired = $false
    }
}

function Install-WslPlatform {
    param(
        [Parameter(Mandatory)]
        [System.Management.Automation.ApplicationInfo]$WslCommand
    )

    if (Test-IsAdministrator) {
        & $WslCommand.Source --install --no-distribution | Out-Host
        $InstallExitCode = $LASTEXITCODE

        return $InstallExitCode
    }

    Write-Host "Requesting elevation to install the WSL platform..."

    $Process = Start-Process `
        -FilePath $WslCommand.Source `
        -ArgumentList @("--install", "--no-distribution") `
        -Verb RunAs `
        -Wait `
        -PassThru

    $Process.ExitCode
}

switch ($Operation) {
    "Get" {
        Get-WslState
        break
    }

    "Test" {
        $State = Get-WslState

        Write-Host "WSL installed:       $($State.Installed)"
        Write-Host "Default WSL version: $($State.DefaultVersion)"

        if (-not $State.InDesiredState) {
            Write-Warning "WSL 2 is not in the desired state."
        }

        $State.InDesiredState
        break
    }

    "Apply" {
        $State = Get-WslState
        $WslCommand = Get-WslCommand

        if ($null -eq $WslCommand) {
            throw "wsl.exe is not available. Install current Windows updates and try again."
        }

        if (-not $State.Installed) {
            Write-Host "Installing WSL without a Linux distribution..."

            $InstallExitCode = Install-WslPlatform -WslCommand $WslCommand

            if ($InstallExitCode -eq 3010) {
                $State.RestartRequired = $true
                $State
                break
            }

            if ($InstallExitCode -ne 0) {
                throw "WSL installation failed with exit code $InstallExitCode."
            }

            $State = Get-WslState

            if (-not $State.Installed) {
                $State.RestartRequired = $true
                $State
                break
            }
        }

        if ($State.DefaultVersion -ne 2) {
            Write-Host "Setting WSL 2 as the default for new distributions..."

            & $WslCommand.Source --set-default-version 2 | Out-Host

            if ($LASTEXITCODE -ne 0) {
                throw "Unable to set WSL 2 as the default. A restart or nested virtualization may be required."
            }
        }

        $State = Get-WslState

        if (-not $State.InDesiredState) {
            throw "WSL configuration completed but did not reach the desired state."
        }

        $State
        break
    }
}
