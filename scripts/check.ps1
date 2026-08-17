$ErrorActionPreference = "Stop"

$Config = Join-Path $PSScriptRoot "..\.config\configuration.winget"

Write-Host "Checking Windows configuration..."
Write-Host ""

winget configure test -f $Config

exit $LASTEXITCODE