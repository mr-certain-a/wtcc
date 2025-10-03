# WTCC Send-KeyCombo 動作確認テスト
# 事前に Notepad を開いてアクティブにしておいてください

# スクリプトルート解決
$here = Split-Path -Path $MyInvocation.MyCommand.Path -Parent
$modulePath = Join-Path $here 'scripts\helpers.psm1'

# ヘルパーモジュールを読み込み
Import-Module -Force -Scope Local -Name $modulePath

Write-Host "3秒後にテスト開始します。Notepad をアクティブにしてください..."
for ($i = 3; $i -ge 1; $i--) {
    Write-Host "$i..."
    Start-Sleep -Seconds 1
}

# 単体 P
Write-Host "`n=== Test1: 単体 P ==="
Send-KeyCombo @(0x50)   # 'p' が入力されるはず
Start-Sleep -Seconds 1

# Shift+P
Write-Host "`n=== Test2: Shift+P ==="
Send-KeyCombo @(0x10,0x50)   # 'P' が入力されるはず
Start-Sleep -Seconds 1

# Ctrl+Shift+P
Write-Host "`n=== Test3: Ctrl+Shift+P ==="
Send-KeyCombo @(0x11,0x10,0x50)   # WT なら「コマンドパレット」が開く組み合わせ
Start-Sleep -Seconds 1

Write-Host "`nテスト完了しました"
