# Repository-managed PowerShell profile.
# Keep shared, non-sensitive, cross-host settings in this file.

$env:EDITOR = "code --wait"
$env:VISUAL = $env:EDITOR

if ($Host.Name -eq "ConsoleHost") {
    try {
        Import-Module PSReadLine -ErrorAction Stop

        $SetOptionCommand = Get-Command `
            -Name "Set-PSReadLineOption" `
            -ErrorAction Stop
        $Options = @{
            EditMode = "Windows"
            HistoryNoDuplicates = $true
        }

        if ($SetOptionCommand.Parameters.ContainsKey("PredictionSource")) {
            $Options.PredictionSource = "History"
        }

        if ($SetOptionCommand.Parameters.ContainsKey("PredictionViewStyle")) {
            $Options.PredictionViewStyle = "ListView"
        }

        Set-PSReadLineOption @Options

        if (Get-Command -Name "Set-PSReadLineKeyHandler" -ErrorAction SilentlyContinue) {
            Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete
        }
    }
    catch {
        Write-Verbose "PSReadLine profile settings were skipped: $($_.Exception.Message)"
    }
}

function Resolve-WindowsConfigRoot {
    [CmdletBinding()]
    param(
        [switch]$PreferLocal
    )

    $LocalRoot = Join-Path $HOME "projects\windows-config"
    $CanonicalRoot = "Y:\projects\windows-config"
    $Candidates = if ($PreferLocal) {
        @($LocalRoot, $CanonicalRoot)
    }
    else {
        @($CanonicalRoot, $LocalRoot)
    }

    foreach ($Candidate in $Candidates) {
        if (Test-Path -LiteralPath $Candidate -PathType Container) {
            return $Candidate
        }
    }

    throw "No windows-config repository is available."
}

function Test-WindowsConfig {
    [CmdletBinding()]
    param()

    $Root = Resolve-WindowsConfigRoot -PreferLocal
    & (Join-Path $Root "scripts\check.ps1")
}

function Update-WindowsConfig {
    [CmdletBinding()]
    param()

    $Root = Resolve-WindowsConfigRoot
    & (Join-Path $Root "scripts\bootstrap.ps1")
}
