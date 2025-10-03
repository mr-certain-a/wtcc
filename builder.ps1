<#
  WTCC builder.ps1
  - 旧 script.txt の手順を PowerShell コマンド化したビルダー本体
  - 依存: 同一ディレクトリの `wtcc.ps1` からロードされる `scripts/helpers.psm1`
  - 前提: `wtcc.ps1` 側で `Set-WTCCInterval` 済み＆WT が起動・アクティブになっていること
#>

# ウィンドウサイズ変更
Invoke-WindowCommand -ArgList @('size','2000','1000')

# builder用ヘルパーモジュールをImport
$paneActions = Join-Path $PSScriptRoot 'scripts/actions/PaneActions.psm1'
Import-Module -Force -Scope Local -Name $paneActions

# 背景色 → 分割 → 背景色
Pane-SetBg '#440011'
Pane-Split 'horizontal'
Pane-SetBg '#111122'
Invoke-PaneCommand -ArgList @('exec','cd ~')
Invoke-PaneCommand -ArgList @('exec','cls')
Invoke-PaneCommand -ArgList @('move','up','1')

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

# 新規タブ（色付き）
Invoke-TabCommand -ArgList @('new','--tabColor','#330033')
Start-Sleep -Milliseconds 1000

# 新タブ側の初期化と分割・色・リサイズ
Pane-SetBg '#1A0000'
Pane-Exec 'cls'
Pane-Split 'vertical'
Pane-Exec 'cls'
Pane-SetBg '#001A00'
Pane-Resize 'right' 2
Pane-Split 'horizontal'
Pane-SetBg '#00001A'
Pane-Resize 'down' 3
Invoke-PaneCommand -ArgList @('exec','cls')

# タブ名変更の表示とリネーム
Pane-Exec 'echo "タブ名を変更する..."'
Invoke-TabCommand -ArgList @('rename','TEST USER')
Start-Sleep -Milliseconds 1000

# 完了メッセージ
Pane-Exec 'echo "ターミナル設定完了"'
