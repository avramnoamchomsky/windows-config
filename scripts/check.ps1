$ErrorActionPreference = "Stop"

$Config = Join-Path $PSScriptRoot "..\.config\configuration.winget"
$WslConfig = Join-Path $PSScriptRoot "..\system\wsl.ps1"
$PowerShellProfileConfig = Join-Path `
    $PSScriptRoot `
    "..\home\powershell\manage-profile.ps1"
$GitConfig = Join-Path $PSScriptRoot "..\home\git\manage-git.ps1"
$Prerequisites = Join-Path $PSScriptRoot "assert-prerequisites.ps1"

& $Prerequisites | Out-Null

Write-Host ""
Write-Host "Checking Windows configuration..."
Write-Host ""

winget configure test -f $Config
$WinGetExitCode = $LASTEXITCODE

Write-Host ""
Write-Host "Checking Git user configuration..."
Write-Host ""

$GitInDesiredState = & $GitConfig -Operation Test

Write-Host ""
Write-Host "Checking PowerShell profile configuration..."
Write-Host ""

$PowerShellProfileInDesiredState = & $PowerShellProfileConfig -Operation Test

Write-Host ""
Write-Host "Checking WSL 2 platform configuration..."
Write-Host ""

$WslInDesiredState = & $WslConfig -Operation Test

if (
    ($WinGetExitCode -ne 0) -or
    (-not $GitInDesiredState) -or
    (-not $PowerShellProfileInDesiredState) -or
    (-not $WslInDesiredState)
) {
    exit 1
}

Write-Host ""
Write-Host "Windows configuration is in the desired state."

exit 0
