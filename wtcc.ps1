# WTCC エントリポイント (Windows Terminal Cockpit Customizer)
param(
    [int]$Interval = 200
)

Write-Host "" 
Write-Host "=============================================" -ForegroundColor Yellow
Write-Host " WTCC: Windowsターミナルを新規に起動してキーボードエミュレーションで設定していきます。" -ForegroundColor Cyan
Write-Host "  → WTの設定によっては動きが異なる場合があります。" -ForegroundColor Cyan
Write-Host "  → チェックなしで順番通りにキーボード入力を送っています。なので噛み合わないと妙なことになります。" -ForegroundColor Cyan
Write-Host "  → 強制終了はこのスクリプトをCtrl+Cで止めてください。" -ForegroundColor Cyan
Write-Host "  → 処理の途中で他のWindowがアクティブになると、そのWindowにキーを送出し続けます。" -ForegroundColor Cyan
Write-Host "  *"
Write-Host "  [⚠注意] setting.jsonに \"windowingBehavior\": \"useExisting\" ではない場合、" -ForegroundColor Red
Write-Host "       新規タブが別ウインドウで作られることがあります。" -ForegroundColor Red
Write-Host "  [⚠注意] 上記の設定をしていても、新規タブが別のWTに作られることもあります。" -ForegroundColor Red
Write-Host "       気になる場合はWTではなくPowerShellから起動すれば大体は大丈夫ですが、最悪あとから結合してください。" -ForegroundColor Red
Write-Host "  [⚠注意] WindowsTerminalのバージョンによってコマンド名が異なる場合があります。 " -ForegroundColor Red
Write-Host "       うまく動かない場合はwt_commands_map.jsonで調整してください。" -ForegroundColor Red
Write-Host "  *"
Write-Host " 上記を理解した上で実行する場合はEnterキーを、やめる場合はCtrl+Cで中断させてください。" -ForegroundColor Blue
Write-Host "=============================================" -ForegroundColor Yellow
Write-Host ""

# キー入力待ち
[void][System.Console]::ReadKey($true)

# カウントダウン
for ($i = 3; $i -ge 1; $i--) {
    Write-Host ("開始まで {0}..." -f $i) -ForegroundColor Green
    Start-Sleep -Seconds 1
}

Write-Host "発射！🚀 マウスやキーボードに触らないで！" -ForegroundColor Red

# 3秒待機後に WT 新規タブ（タイトル=WTCC）を起動
try {
    Start-Process -FilePath 'wt' -ArgumentList "-w -1 new-tab --title WTCC" -WindowStyle Normal | Out-Null
    Start-Sleep -Seconds 3
} catch {
    Write-Warning "wt の起動に失敗: $($_.Exception.Message)"
}

$ErrorActionPreference = 'Stop'

# スクリプトルート解決
$here = Split-Path -Path $MyInvocation.MyCommand.Path -Parent
$modulePath = Join-Path $here 'scripts\helpers.psm1'
Import-Module -Force -Scope Local -Name $modulePath -DisableNameChecking

# インターバル設定
Set-WTCCInterval -Interval $Interval

# builder.ps1 を呼び出す（script.txt は完全廃止）
$builder = Join-Path $here 'builder.ps1'
if (-not (Test-Path -LiteralPath $builder)) {
    throw "builder.ps1 が見つからない: $builder"
}
Write-Host ("WTCC: builder を実行するよ -> {0} (Interval={1}ms)" -f $builder, $Interval) -ForegroundColor Cyan

& $builder

Write-Host "WTCC: 実行完了だよん?" -ForegroundColor Green
