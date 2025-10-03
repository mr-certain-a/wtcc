param(
    [int]$Interval = 60
)

$here = Split-Path -Path $MyInvocation.MyCommand.Path -Parent
Import-Module -Force -Scope Local -Name (Join-Path $here '..\scripts\helpers.psm1')

Write-Host '=== WTCC Send-KeyCombo テスト ===' -ForegroundColor Cyan
Write-Host '1) ノートパッド（Notepad）を開いてアクティブにしてね。' -ForegroundColor Yellow
Write-Host '2) Enterを押すと3秒カウント後に送出開始するよ。' -ForegroundColor Yellow
Read-Host '準備できたら Enter'

Set-WTCCInterval -Interval $Interval

1..3 | ForEach-Object { Write-Host ("開始まで {0}..." -f (4-$_)); Start-Sleep -Seconds 1 }

# ここから送出（コンボ）
# Shift+H, Shift+I で "HI"
Send-KeyCombo @(0x10, 0x48) # SHIFT + H
Send-KeyCombo @(0x10, 0x49) # SHIFT + I
Send-Key 0x20               # Space

# SHIFT + WORLD（各文字をSHIFT押下で大文字）
Send-KeyCombo @(0x10, 0x57) # W
Send-KeyCombo @(0x10, 0x4F) # O
Send-KeyCombo @(0x10, 0x52) # R
Send-KeyCombo @(0x10, 0x4C) # L
Send-KeyCombo @(0x10, 0x44) # D
Send-Key 0x0D               # Enter

# Ctrl+A, Ctrl+C などの修飾テスト（安全な範囲）
Send-KeyCombo @(0x11, 0x41) # Ctrl + A (全選択)
Send-KeyCombo @(0x11, 0x43) # Ctrl + C (コピー)
Send-Key 0x0D               # Enter で改行

Write-Host '送出完了！画面を確認してね。' -ForegroundColor Green
