$ErrorActionPreference = "Stop"

Write-Host "Bootstrapping Windows configuration..."

if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    throw "WinGet is not installed. Install or update App Installer, then run this script again."
}

$VersionText = winget --version

Write-Host "WinGet: $VersionText"
Write-Host ""

& (Join-Path $PSScriptRoot "apply.ps1")

exit $LASTEXITCODE