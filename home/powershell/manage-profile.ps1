[CmdletBinding()]
param(
    [ValidateSet("Get", "Test", "Apply")]
    [string]$Operation = "Test"
)

$ErrorActionPreference = "Stop"

$SourceProfile = Join-Path $PSScriptRoot "profile.ps1"
$ManagedProfile = Join-Path `
    $env:USERPROFILE `
    ".config\windows-config\powershell\profile.ps1"

$StartMarker = "# >>> windows-config >>>"
$EndMarker = "# <<< windows-config <<<"
$ManagedBlock = @'
# >>> windows-config >>>
$WindowsConfigProfile = Join-Path $HOME ".config\windows-config\powershell\profile.ps1"
if (Test-Path -LiteralPath $WindowsConfigProfile) {
    . $WindowsConfigProfile
}
# <<< windows-config <<<
'@

function Get-ProfileTargets {
    $Documents = [Environment]::GetFolderPath("MyDocuments")

    @(
        [pscustomobject]@{
            Name = "PowerShell 7"
            Path = (Join-Path $Documents "PowerShell\profile.ps1")
        }
        [pscustomobject]@{
            Name = "Windows PowerShell"
            Path = (Join-Path $Documents "WindowsPowerShell\profile.ps1")
        }
    )
}

function ConvertTo-NormalizedContent {
    param(
        [AllowNull()]
        [string]$Content
    )

    if ($null -eq $Content) {
        return ""
    }

    $Content.Replace("`r`n", "`n").TrimEnd()
}

function Get-ManagedBlockPattern {
    $EscapedStart = [regex]::Escape($StartMarker)
    $EscapedEnd = [regex]::Escape($EndMarker)

    [regex]::new(
        "$EscapedStart.*?$EscapedEnd",
        [Text.RegularExpressions.RegexOptions]::Singleline
    )
}

function Test-DeployedProfile {
    if (-not (Test-Path -LiteralPath $ManagedProfile -PathType Leaf)) {
        return $false
    }

    $SourceContent = Get-Content -LiteralPath $SourceProfile -Raw
    $DeployedContent = Get-Content -LiteralPath $ManagedProfile -Raw
    $NormalizedSource = ConvertTo-NormalizedContent $SourceContent
    $NormalizedDeployed = ConvertTo-NormalizedContent $DeployedContent

    $NormalizedSource -ceq $NormalizedDeployed
}

function Test-ProfileLoader {
    param(
        [Parameter(Mandatory)]
        [string]$Path
    )

    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        return $false
    }

    $Content = Get-Content -LiteralPath $Path -Raw
    $Pattern = Get-ManagedBlockPattern
    $Matches = $Pattern.Matches([string]$Content)

    if ($Matches.Count -ne 1) {
        return $false
    }

    $ActualBlock = ConvertTo-NormalizedContent $Matches[0].Value
    $ExpectedBlock = ConvertTo-NormalizedContent $ManagedBlock

    $ActualBlock -ceq $ExpectedBlock
}

function Get-ManagedProfileState {
    $ProfileStates = @(
        Get-ProfileTargets | ForEach-Object {
            [pscustomobject]@{
                Name = $_.Name
                Path = $_.Path
                InDesiredState = (Test-ProfileLoader -Path $_.Path)
            }
        }
    )

    $SourceDeployed = Test-DeployedProfile
    $ProfilesReady = @(
        $ProfileStates | Where-Object { -not $_.InDesiredState }
    ).Count -eq 0

    [pscustomobject]@{
        SourcePath = $SourceProfile
        ManagedPath = $ManagedProfile
        SourceDeployed = $SourceDeployed
        Profiles = $ProfileStates
        InDesiredState = $SourceDeployed -and $ProfilesReady
    }
}

function Backup-ProfileOnce {
    param(
        [Parameter(Mandatory)]
        [string]$Path
    )

    $BackupPath = "$Path.windows-config.bak"

    if (-not (Test-Path -LiteralPath $BackupPath)) {
        Copy-Item -LiteralPath $Path -Destination $BackupPath
        Write-Host "Backed up existing profile to: $BackupPath"
    }
}

function Set-ProfileLoader {
    param(
        [Parameter(Mandatory)]
        [string]$Path
    )

    $Parent = Split-Path -Parent $Path
    New-Item -ItemType Directory -Path $Parent -Force | Out-Null

    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        Set-Content `
            -LiteralPath $Path `
            -Value $ManagedBlock `
            -Encoding utf8

        return
    }

    $Content = [string](Get-Content -LiteralPath $Path -Raw)
    $StartCount = ([regex]::Matches($Content, [regex]::Escape($StartMarker))).Count
    $EndCount = ([regex]::Matches($Content, [regex]::Escape($EndMarker))).Count

    if ($StartCount -ne $EndCount) {
        throw "Profile contains an unmatched windows-config marker: $Path"
    }

    if ($StartCount -gt 1) {
        throw "Profile contains multiple windows-config blocks: $Path"
    }

    if ($StartCount -eq 1) {
        $Pattern = Get-ManagedBlockPattern

        if (-not (Test-ProfileLoader -Path $Path)) {
            Backup-ProfileOnce -Path $Path
            $Match = $Pattern.Match($Content)
            $Content = $Content.Substring(0, $Match.Index) +
                $ManagedBlock +
                $Content.Substring($Match.Index + $Match.Length)

            Set-Content `
                -LiteralPath $Path `
                -Value $Content `
                -Encoding utf8
        }

        return
    }

    Backup-ProfileOnce -Path $Path

    if ([string]::IsNullOrEmpty($Content)) {
        $NewContent = $ManagedBlock
    }
    elseif ($Content.EndsWith("`n")) {
        $NewContent = $Content +
            [Environment]::NewLine +
            $ManagedBlock
    }
    else {
        $NewContent = $Content +
            [Environment]::NewLine +
            [Environment]::NewLine +
            $ManagedBlock
    }

    Set-Content `
        -LiteralPath $Path `
        -Value $NewContent `
        -Encoding utf8
}

switch ($Operation) {
    "Get" {
        Get-ManagedProfileState
        break
    }

    "Test" {
        $State = Get-ManagedProfileState

        Write-Host "Managed profile deployed: $($State.SourceDeployed)"

        foreach ($Profile in $State.Profiles) {
            Write-Host "$($Profile.Name) loader: $($Profile.InDesiredState)"
        }

        if (-not $State.InDesiredState) {
            Write-Warning "PowerShell profiles are not in the desired state."
        }

        $State.InDesiredState
        break
    }

    "Apply" {
        if (-not (Test-Path -LiteralPath $SourceProfile -PathType Leaf)) {
            throw "Managed profile source is missing: $SourceProfile"
        }

        $ManagedParent = Split-Path -Parent $ManagedProfile
        New-Item -ItemType Directory -Path $ManagedParent -Force | Out-Null
        Copy-Item `
            -LiteralPath $SourceProfile `
            -Destination $ManagedProfile `
            -Force

        foreach ($Profile in (Get-ProfileTargets)) {
            Write-Host "Configuring $($Profile.Name) profile..."
            Set-ProfileLoader -Path $Profile.Path
        }

        $State = Get-ManagedProfileState

        if (-not $State.InDesiredState) {
            throw "PowerShell profiles did not reach the desired state."
        }

        $State
        break
    }
}
