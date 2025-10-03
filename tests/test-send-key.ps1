param(
    [int]$Interval = 50
)

$here = Split-Path -Path $MyInvocation.MyCommand.Path -Parent
Import-Module -Force -Scope Local -Name (Join-Path $here '..\scripts\helpers.psm1')

Write-Host '=== WTCC Send-Key テスト ===' -ForegroundColor Cyan
Write-Host '1) ノートパッド（Notepad）を開いてアクティブにしてね。' -ForegroundColor Yellow
Write-Host '2) Enterを押すと3秒カウント後に送出開始するよ。' -ForegroundColor Yellow
Read-Host '準備できたら Enter'

Set-WTCCInterval -Interval $Interval

1..3 | ForEach-Object { Write-Host ("開始まで {0}..." -f (4-$_)); Start-Sleep -Seconds 1 }

# ここから送出（単発キー）
Send-Key 0x48 # H
Send-Key 0x45 # E
Send-Key 0x4C # L
Send-Key 0x4C # L
Send-Key 0x4F # O
Send-Key 0x20 # Space
Send-Key 0x57 # W
Send-Key 0x4F # O
Send-Key 0x52 # R
Send-Key 0x4C # L
Send-Key 0x44 # D
Send-Key 0x0D # Enter

Write-Host '送出完了！画面を確認してね。' -ForegroundColor Green
