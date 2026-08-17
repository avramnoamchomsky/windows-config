[CmdletBinding()]
param(
    [string]$LocalRepo = (
        Join-Path $env:USERPROFILE "projects\windows-config"
    )
)

$ErrorActionPreference = "Stop"

$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$LocalRepo = [System.IO.Path]::GetFullPath($LocalRepo)

Write-Host "Windows configuration bootstrap"
Write-Host ""
Write-Host "Repository: $RepoRoot"
Write-Host "Local copy: $LocalRepo"
Write-Host ""

if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    throw "WinGet is not available."
}

Write-Host "WinGet: $(winget --version)"
Write-Host ""

$Current = $RepoRoot.TrimEnd("\")
$Target = $LocalRepo.TrimEnd("\")

if ($Current -ine $Target) {
    Write-Host "Staging configuration on the local drive..."

    & (Join-Path $PSScriptRoot "copy-local.ps1") `
        -Destination $LocalRepo `
        -Clean

    Write-Host ""
    Write-Host "Applying configuration from local copy..."

    & (Join-Path $LocalRepo "scripts\apply.ps1")

    exit $LASTEXITCODE
}

Write-Host "Already running from the local copy."
Write-Host "Applying configuration..."

& (Join-Path $PSScriptRoot "apply.ps1")

exit $LASTEXITCODE