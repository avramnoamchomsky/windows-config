[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"

if ($env:OS -ne "Windows_NT") {
    throw "This configuration requires Windows 11."
}

$WindowsVersionKey = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion"
$WindowsVersionInfo = Get-ItemProperty -LiteralPath $WindowsVersionKey
$WindowsBuild = [int]$WindowsVersionInfo.CurrentBuildNumber
$WindowsVersion = "$($WindowsVersionInfo.ProductName) $($WindowsVersionInfo.DisplayVersion) (build $WindowsBuild)"

if ($WindowsBuild -lt 22000) {
    throw "Windows 11 build 22000 or later is required. Found $WindowsVersion."
}

$WinGetCommand = Get-Command `
    -Name "winget.exe" `
    -CommandType Application `
    -ErrorAction SilentlyContinue |
    Select-Object -First 1

if ($null -eq $WinGetCommand) {
    throw "WinGet is not available. Install or update App Installer and try again."
}

$VersionText = (& $WinGetCommand.Source --version).Trim()

if ($LASTEXITCODE -ne 0) {
    throw "Unable to determine the WinGet version."
}

$VersionMatch = [regex]::Match($VersionText, '\d+(?:\.\d+){1,3}')

if (-not $VersionMatch.Success) {
    throw "Unable to parse the WinGet version: $VersionText"
}

$WinGetVersion = [version]$VersionMatch.Value
$MinimumWinGetVersion = [version]"1.11"

if ($WinGetVersion -lt $MinimumWinGetVersion) {
    throw "WinGet $MinimumWinGetVersion or later is required for DSC v3. Found $VersionText."
}

$WslCommand = Get-Command `
    -Name "wsl.exe" `
    -CommandType Application `
    -ErrorAction SilentlyContinue |
    Select-Object -First 1

if ($null -eq $WslCommand) {
    throw "wsl.exe is not available. Install current Windows updates and try again."
}

Write-Host "Windows: $WindowsVersion"
Write-Host "WinGet:  $VersionText"
Write-Host "WSL CLI: $($WslCommand.Source)"

[pscustomobject]@{
    WindowsVersion = $WindowsVersion
    WindowsBuild = $WindowsBuild
    WinGetVersion = $WinGetVersion
    WinGetPath = $WinGetCommand.Source
    WslPath = $WslCommand.Source
}
