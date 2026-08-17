$ErrorActionPreference = "Stop"

$Config = Join-Path $PSScriptRoot "..\.config\configuration.winget"

Write-Host "Validating WinGet configuration..."
winget configure validate -f $Config

if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}

Write-Host ""
Write-Host "Checking desired state..."
winget configure test -f $Config
$ErrorActionPreference = "Stop"

$Config = Join-Path $PSScriptRoot "..\.config\configuration.winget"

Write-Host "Validating WinGet configuration..."
winget configure validate -f $Config

if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}

Write-Host ""
Write-Host "Checking desired state..."
winget configure test -f $Config

exit $LASTEXITCODE
exit $LASTEXITCODE