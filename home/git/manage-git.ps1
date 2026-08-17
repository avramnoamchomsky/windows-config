[CmdletBinding()]
param(
    [ValidateSet("Get", "Test", "Apply")]
    [string]$Operation = "Test"
)

$ErrorActionPreference = "Stop"

$DesiredSettings = [ordered]@{
    "init.defaultBranch" = "main"
    "fetch.prune" = "true"
    "push.autoSetupRemote" = "true"
    "core.longpaths" = "true"
    "core.editor" = "code --wait"
}

function Get-GitCommand {
    Get-Command `
        -Name "git.exe" `
        -CommandType Application `
        -ErrorAction SilentlyContinue |
        Select-Object -First 1
}

function Get-GitSettingValues {
    param(
        [Parameter(Mandatory)]
        [System.Management.Automation.ApplicationInfo]$GitCommand,

        [Parameter(Mandatory)]
        [string]$Key
    )

    $Values = @(
        & $GitCommand.Source config --global --get-all $Key 2>$null
    )
    $ExitCode = $LASTEXITCODE

    if ($ExitCode -notin @(0, 1)) {
        throw "Unable to read global Git setting '$Key' (exit code $ExitCode)."
    }

    $Values
}

function Get-GitState {
    $GitCommand = Get-GitCommand
    $SettingStates = @()

    foreach ($Setting in $DesiredSettings.GetEnumerator()) {
        $ActualValues = @()

        if ($null -ne $GitCommand) {
            $ActualValues = @(
                Get-GitSettingValues `
                    -GitCommand $GitCommand `
                    -Key $Setting.Key
            )
        }

        $SettingStates += [pscustomobject]@{
            Key = $Setting.Key
            DesiredValue = $Setting.Value
            ActualValues = $ActualValues
            InDesiredState = (
                ($ActualValues.Count -eq 1) -and
                ($ActualValues[0] -ceq $Setting.Value)
            )
        }
    }

    $SettingsReady = @(
        $SettingStates | Where-Object { -not $_.InDesiredState }
    ).Count -eq 0
    $CommandPath = if ($null -ne $GitCommand) {
        $GitCommand.Source
    }
    else {
        $null
    }

    [pscustomobject]@{
        CommandAvailable = $null -ne $GitCommand
        CommandPath = $CommandPath
        Settings = $SettingStates
        InDesiredState = ($null -ne $GitCommand) -and $SettingsReady
    }
}

switch ($Operation) {
    "Get" {
        Get-GitState
        break
    }

    "Test" {
        $State = Get-GitState

        Write-Host "Git available: $($State.CommandAvailable)"

        foreach ($Setting in $State.Settings) {
            Write-Host "$($Setting.Key): $($Setting.InDesiredState)"
        }

        if (-not $State.InDesiredState) {
            Write-Warning "Git user configuration is not in the desired state."
        }

        $State.InDesiredState
        break
    }

    "Apply" {
        $GitCommand = Get-GitCommand

        if ($null -eq $GitCommand) {
            throw "Git is not available after package configuration."
        }

        foreach ($Setting in $DesiredSettings.GetEnumerator()) {
            Write-Host "Setting $($Setting.Key)=$($Setting.Value)"

            & $GitCommand.Source `
                config `
                --global `
                --replace-all `
                $Setting.Key `
                $Setting.Value |
                Out-Host

            if ($LASTEXITCODE -ne 0) {
                throw "Unable to set global Git setting '$($Setting.Key)'."
            }
        }

        $State = Get-GitState

        if (-not $State.InDesiredState) {
            throw "Git user configuration did not reach the desired state."
        }

        $State
        break
    }
}
