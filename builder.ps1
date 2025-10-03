<#
  WTCC builder.ps1
  - 旧 script.txt の手順を PowerShell コマンド化したビルダー本体
  - 依存: 同一ディレクトリの `wtcc.ps1` からロードされる `scripts/helpers.psm1`
  - 前提: `wtcc.ps1` 側で `Set-WTCCInterval` 済み＆WT が起動・アクティブになっていること
#>

# ウィンドウサイズ変更
Invoke-WindowCommand -ArgList @('size','2000','1000')

# 最初のペイン装飾・分割（可読性向上のため関数化）
$split  = Join-Path $PSScriptRoot 'scripts/actions/split.ps1'
$setbg  = Join-Path $PSScriptRoot 'scripts/actions/set-bg.ps1'
$resize = Join-Path $PSScriptRoot 'scripts/actions/resize.ps1'

function PaneAction-Split([ValidateSet('vertical','horizontal')]$Mode) {
    $cmd = "powershell -NoProfile -ExecutionPolicy Bypass -File '{0}' -Mode '{1}'" -f $split, $Mode
    Invoke-PaneCommand -ArgList @('exec', $cmd)
}

function PaneAction-SetBg([string]$Color) {
    $cmd = "powershell -NoProfile -ExecutionPolicy Bypass -File '{0}' -Color '{1}'" -f $setbg, $Color
    Invoke-PaneCommand -ArgList @('exec', $cmd)
}

function PaneAction-Resize([ValidateSet('left','right','up','down')]$Direction, [int]$Count = 1) {
    $cmd = "powershell -NoProfile -ExecutionPolicy Bypass -File '{0}' -Direction '{1}' -Count {2}" -f $resize, $Direction, $Count
    Invoke-PaneCommand -ArgList @('exec', $cmd)
}

# 背景色 → 分割 → 背景色
PaneAction-SetBg '#440011'
PaneAction-Split 'horizontal'
PaneAction-SetBg '#111122'
Invoke-PaneCommand -ArgList @('exec','cd ~')
Invoke-PaneCommand -ArgList @('exec','cls')
Invoke-PaneCommand -ArgList @('move','up','1')

# サイズ調整＆初期化（関数経由）
PaneAction-Resize 'down' 2
Invoke-PaneCommand -ArgList @('exec','cd ~')
Invoke-PaneCommand -ArgList @('exec','cls')

# さらに分割して背景色（関数経由）
PaneAction-Split 'vertical'
PaneAction-SetBg '#004411'

# タブ名とキー送出、軽く掃除
Invoke-TabCommand -ArgList @('rename','WTCC USER')
Invoke-KeyCommand -ArgList @('enter')
Invoke-PaneCommand -ArgList @('exec','cls')

# 新規タブ（色付き）
Invoke-TabCommand -ArgList @('new','--tabColor','#330033')
Start-Sleep -Milliseconds 1000

# 新タブ側の初期化と分割・色・リサイズ
PaneAction-SetBg '#1A0000'
 Invoke-PaneCommand -ArgList @('exec','cls')
PaneAction-Split 'vertical'
 Invoke-PaneCommand -ArgList @('exec','cls')
PaneAction-SetBg '#001A00'
PaneAction-Resize 'right' 2
PaneAction-Split 'horizontal'
PaneAction-SetBg '#00001A'
PaneAction-Resize 'down' 3
Invoke-PaneCommand -ArgList @('exec','cls')

# タブ名変更の表示とリネーム
Invoke-PaneCommand -ArgList @('exec','echo "タブ名を変更する..."')
Invoke-TabCommand -ArgList @('rename','TEST USER')
Start-Sleep -Milliseconds 1000

# 完了メッセージ
Invoke-PaneCommand -ArgList @('exec','echo "ターミナル設定完了"')
