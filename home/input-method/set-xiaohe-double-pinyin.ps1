[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

if ($env:OS -ne "Windows_NT") {
    throw "This script can only run on Windows."
}

$RegistryPath = "HKCU:\Software\Microsoft\InputMethod\Settings\CHS"
$ValueName = "UserDefinedDoublePinyinScheme0"
$SchemeName = -join @(
    [char]0x5C0F,
    [char]0x9E64,
    [char]0x53CC,
    [char]0x62FC
)
$DesiredValue = "$SchemeName*2*^*iuvdjhcwfg^xmlnpbksqszxkrltvyovt"
$CurrentValue = $null

if (Test-Path -LiteralPath $RegistryPath) {
    $CurrentValue = Get-ItemPropertyValue `
        -LiteralPath $RegistryPath `
        -Name $ValueName `
        -ErrorAction SilentlyContinue
}

if ($CurrentValue -ceq $DesiredValue) {
    Write-Host "Xiaohe double-pinyin scheme is already configured."
    exit 0
}

New-Item -Path $RegistryPath -Force | Out-Null
New-ItemProperty `
    -LiteralPath $RegistryPath `
    -Name $ValueName `
    -PropertyType String `
    -Value $DesiredValue `
    -Force | Out-Null

$AppliedValue = Get-ItemPropertyValue `
    -LiteralPath $RegistryPath `
    -Name $ValueName

if ($AppliedValue -cne $DesiredValue) {
    throw "The Xiaohe double-pinyin registry value could not be verified."
}

Write-Host "Xiaohe double-pinyin scheme configured successfully."
