$ErrorActionPreference = "Stop"

$Config = Join-Path $PSScriptRoot "..\.config\configuration.winget"

Write-Host "Applying Windows configuration..."

winget configure `
    -f $Config `
    --accept-configuration-agreements

exit $LASTEXITCODE