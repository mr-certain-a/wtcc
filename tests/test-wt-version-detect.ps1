param()

$ErrorActionPreference = 'Stop'

Write-Host '=== WTCC Windows Terminal Version Detect (Actual Env) ===' -ForegroundColor Cyan

# Ensure no override is in effect
Remove-Item Env:\WTCC_WT_VERSION -ErrorAction SilentlyContinue | Out-Null

$here = Split-Path -Path $MyInvocation.MyCommand.Path -Parent
$modulePath = Join-Path $here '..\scripts\helpers.psm1'

# Import helpers and verify export
Get-Module | Where-Object { $_.Name -eq 'helpers' } | ForEach-Object { Remove-Module $_ -Force }
$m = Import-Module -Force -Name $modulePath -PassThru
if (-not $m) { Write-Error "Import-Module failed: $modulePath"; exit 1 }
if (-not (Get-Command -Module $m -Name Get-WTCCWTVersion -ErrorAction SilentlyContinue)) {
  Write-Error 'Get-WTCCWTVersion is not exported from helpers module'; exit 1
}

# Actual detection via helper
$actual = Get-WTCCWTVersion
Write-Host ("Detected (helpers): {0}" -f ($actual ?? '<empty>')) -ForegroundColor Yellow

# Independent detection via Appx
$pkg = Get-AppxPackage -Name 'Microsoft.WindowsTerminal' -ErrorAction SilentlyContinue | Select-Object -First 1 -Property Version
$expected = if ($pkg) { [string]$pkg.Version } else { '' }
Write-Host ("Expected (Appx):  {0}" -f ([string]::IsNullOrWhiteSpace($expected) ? '<empty>' : $expected)) -ForegroundColor Yellow

if ([string]::IsNullOrWhiteSpace($expected) -and [string]::IsNullOrWhiteSpace($actual)) {
  Write-Warning 'Windows Terminal not found. SKIP.'
  exit 0
}

if ($expected -ne $actual) {
  Write-Error ("Version mismatch: expected='{0}', actual='{1}'" -f $expected, $actual)
  exit 1
}

Write-Host 'OK: actual Windows Terminal version detected correctly.' -ForegroundColor Green
exit 0

