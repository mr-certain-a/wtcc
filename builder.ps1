<#
  WTCC builder.ps1
  - 依存: 同一ディレクトリの `wtcc.ps1` からロードされる `scripts/helpers.psm1`
#>

# 直接実行されるケースに備えて helpers.psm1 をロード
$helpers = Join-Path $PSScriptRoot 'scripts/helpers.psm1'
if (-not (Get-Command Invoke-PaneCommand -ErrorAction SilentlyContinue)) {
  if (Test-Path -LiteralPath $helpers) { Import-Module -Force -Scope Local -Name $helpers -DisableNameChecking }
}

# builder用ヘルパーモジュールをImport
$paneActions = Join-Path $PSScriptRoot 'scripts/actions/PaneActions.psm1'
Import-Module -Force -Scope Local -Name $paneActions -DisableNameChecking
$tabActions  = Join-Path $PSScriptRoot 'scripts/actions/TabActions.psm1'
Import-Module -Force -Scope Local -Name $tabActions -DisableNameChecking
$profileActions  = Join-Path $PSScriptRoot 'scripts/actions/ProfileActions.psm1'
Import-Module -Force -Scope Local -Name $profileActions -DisableNameChecking

#######################################################################################
# ↓↓↓ ここから編集してね ↓↓↓
#######################################################################################

# ウィンドウサイズ変更
Invoke-WindowCommand -ArgList @('size','2000','1000')

# 背景色 → 分割 → 背景色
Pane-SetBg '#440011'
Pane-Split 'horizontal'
Pane-SetBg '#111122'
Pane-Exec 'cd ~'
Pane-Exec 'cls'
Pane-Move 'up' 1

# サイズ調整＆初期化（関数経由）
Pane-Resize 'down' 2
Pane-Exec 'cd ~'
Pane-Exec 'cls'

# さらに分割して背景色（関数経由）
Pane-Split 'vertical'
Pane-SetBg '#004411'

# タブ名とキー送出、軽く掃除
Invoke-TabCommand -ArgList @('rename','WTCC USER')
Invoke-KeyCommand -ArgList @('enter')
Pane-Exec 'cls'

# 新規タブサンプル（XUMI）

# プロファイルの作成（同一Name存在時は元設定を触らずスキップ、なにも更新されない）
Profile-Add -Name 'XUMI' -RawJson '
    "font":{"face":"PlemolJP Console"},
    "hidden":false,
    "opacity":70,
    "startingDirectory":"G:\\XUMI",
    "useAcrylic":true,
    "backgroundImage":"xumi_sofa.png",
    "backgroundImageOpacity":0.15,
    "backgroundImageStretchMode":"uniformToFill",
    "icon":"3dicons-bulb-dynamic-color.png",
    "suppressApplicationTitle":true,
    "commandline":"C:\\Program Files\\PowerShell\\7\\pwsh.exe"
'

# プロファイル XUMI を使って起動
Tab-Create "--tabColor '#330033' -p 'XUMI'"

# 念の為1秒待機
Start-Sleep -Milliseconds 1000

# 新タブ側の初期化と分割・色・リサイズ

# 左ペイン
Pane-Exec 'cls'

# 垂直分割
Pane-Split 'vertical'
Pane-SetBg '#1A0000'
Pane-Exec 'cls'

# さらに水平分割
Pane-Split 'horizontal'
Pane-SetBg '#00001A'
Pane-Resize 'down' 2

# タブ名変更の表示とリネーム
Invoke-TabCommand -ArgList @('rename','XUMI')
Start-Sleep -Milliseconds 1000

Pane-Exec 'cls'

# 完了メッセージ
Pane-Exec 'Write-Host "　　🆗ターミナル設定完了🆗　　" -ForegroundColor DarkBlue -BackgroundColor Yellow'

Pane-Move 'up' 1
Pane-Move 'left' 1
Pane-Exec 'codex --full-auto'
