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
Write-Host "Applying Windows configuration..."

winget configure `
    -f $Config `
    --accept-configuration-agreements

if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}

Write-Host ""
Write-Host "Applying Git user configuration..."

$GitState = & $GitConfig -Operation Apply

if (-not $GitState.InDesiredState) {
    throw "Git user configuration did not reach the desired state."
}

Write-Host ""
Write-Host "Applying PowerShell profile configuration..."

$PowerShellProfileState = & $PowerShellProfileConfig -Operation Apply

if (-not $PowerShellProfileState.InDesiredState) {
    throw "PowerShell profiles did not reach the desired state."
}

Write-Host ""
Write-Host "Applying WSL 2 platform configuration..."

$WslState = & $WslConfig -Operation Apply

if ($WslState.RestartRequired) {
    Write-Warning "WSL installation completed, but Windows must be restarted before configuration can finish."
    exit 3010
}

if (-not $WslState.InDesiredState) {
    throw "WSL did not reach the desired state."
}

Write-Host ""
Write-Host "Windows configuration successfully applied."

exit 0
