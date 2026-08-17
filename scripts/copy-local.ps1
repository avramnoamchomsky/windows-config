[CmdletBinding()]
param(
    [string]$Destination = (Join-Path $env:USERPROFILE "projects\windows-config"),

    # Use this if you want the destination to become an exact fresh copy.
    [switch]$Clean
)

$ErrorActionPreference = "Stop"

# The repository root is one level above scripts/.
$Source = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$Destination = [System.IO.Path]::GetFullPath($Destination)

Write-Host "Source:      $Source"
Write-Host "Destination: $Destination"
Write-Host ""

if ($Source.TrimEnd("\") -ieq $Destination.TrimEnd("\")) {
    throw "Source and destination are the same directory."
}

if ($Clean -and (Test-Path -LiteralPath $Destination)) {
    Write-Host "Removing existing destination..."
    Remove-Item -LiteralPath $Destination -Recurse -Force
}

New-Item -ItemType Directory -Path $Destination -Force | Out-Null

Write-Host "Copying repository..."

# -Force ensures hidden items such as .git and .config are included.
Get-ChildItem -LiteralPath $Source -Force | ForEach-Object {
    Copy-Item `
        -LiteralPath $_.FullName `
        -Destination $Destination `
        -Recurse `
        -Force
}

Write-Host ""
Write-Host "Copy complete."
Write-Host ""
Write-Host "Local repository:"
Write-Host "  $Destination"
Write-Host ""
Write-Host "Next:"
Write-Host "  cd `"$Destination`""
Write-Host "  .\scripts\check.ps1"
Write-Host "  .\scripts\apply.ps1"