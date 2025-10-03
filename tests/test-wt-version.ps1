param(
    [string]$OverrideVersion,
    [switch]$CheckMapping
)

$ErrorActionPreference = 'Stop'
$here = Split-Path -Path $MyInvocation.MyCommand.Path -Parent
$modulePath = Join-Path $here '..\scripts\helpers.psm1'

function Import-WTCC {
    param([string]$VersionOverride)
    if ($PSBoundParameters.ContainsKey('VersionOverride') -and -not [string]::IsNullOrWhiteSpace($VersionOverride)) {
        $env:WTCC_WT_VERSION = $VersionOverride
    } else {
        Remove-Item Env:\WTCC_WT_VERSION -ErrorAction SilentlyContinue | Out-Null
    }
    Get-Module | Where-Object { $_.Name -eq 'helpers' } | ForEach-Object { Remove-Module $_ -Force }
    $m = Import-Module -Force -Name $modulePath -PassThru
    if (-not $m) { throw "Import-Module failed: $modulePath" }
    $cmd = Get-Command -Module $m -Name Get-WTCCWTVersion -ErrorAction SilentlyContinue
    if (-not $cmd) { throw 'Get-WTCCWTVersion is not exported from module' }
}

Write-Host '=== WTCC Windows Terminal Version Test ===' -ForegroundColor Cyan

# 1) Actual environment (no override)
Import-WTCC
if (-not (Get-Command -Name Get-WTCCWTVersion -ErrorAction SilentlyContinue)) { throw 'Get-WTCCWTVersion not found after import' }
$actual = Get-WTCCWTVersion
Write-Host ("Detected WT Version: {0}" -f ($actual ?? '<empty>')) -ForegroundColor Yellow
if ($CheckMapping) {
    $name = Get-WTCCWTCommand -Key 'rename-tab' -Default 'Rename tab'
    Write-Host ("Mapping(rename-tab): {0}" -f $name) -ForegroundColor DarkCyan
}

$fails = 0

# 2) Simulate 1.22.X
Import-WTCC -VersionOverride '1.22.1234.0'
$v122 = Get-WTCCWTVersion
$cmd122 = Get-WTCCWTCommand -Key 'rename-tab' -Default 'Rename tab'
Write-Host ("Simulated 1.22 -> Version={0}, rename-tab='{1}'" -f $v122, $cmd122)
if ($cmd122 -ne 'タブ名を変更') { Write-Warning "Expect 'タブ名を変更' for 1.22.* but got '$cmd122'"; $fails++ }

# 3) Simulate 1.21.X
Import-WTCC -VersionOverride '1.21.9999.0'
$v121 = Get-WTCCWTVersion
$cmd121 = Get-WTCCWTCommand -Key 'rename-tab' -Default 'Rename tab'
Write-Host ("Simulated 1.21 -> Version={0}, rename-tab='{1}'" -f $v121, $cmd121)
if ($cmd121 -ne '[名前の変更] タブ') { Write-Warning "Expect '[名前の変更] タブ' for 1.21.* but got '$cmd121'"; $fails++ }

if ($fails -gt 0) { Write-Host ("FAILED: {0} case(s)" -f $fails) -ForegroundColor Red; exit 1 } else { Write-Host 'OK: version mapping tests passed' -ForegroundColor Green }
