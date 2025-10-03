<#
  WTCC builder.ps1
  - 旧 script.txt の手順を PowerShell コマンド化したビルダー本体
  - 依存: 同一ディレクトリの `wtcc.ps1` からロードされる `scripts/helpers.psm1`
  - 前提: `wtcc.ps1` 側で `Set-WTCCInterval` 済み＆WT が起動・アクティブになっていること
#>

# ウィンドウサイズ変更
Invoke-WindowCommand -ArgList @('size','2000','1000')

# 最初のペイン装飾・分割
Invoke-PaneCommand -ArgList @('bg','#440011')
Invoke-PaneCommand -ArgList @('split','horizontal')
Invoke-PaneCommand -ArgList @('bg','#111122')
Invoke-PaneCommand -ArgList @('exec','cd ~')
Invoke-PaneCommand -ArgList @('exec','cls')
Invoke-PaneCommand -ArgList @('move','up','1')

# サイズ調整＆初期化
Invoke-PaneCommand -ArgList @('resize','down','2')
Invoke-PaneCommand -ArgList @('exec','cd ~')
Invoke-PaneCommand -ArgList @('exec','cls')

# さらに分割して背景色
Invoke-PaneCommand -ArgList @('split','vertical')
Invoke-PaneCommand -ArgList @('bg','#004411')

# タブ名とキー送出、軽く掃除
Invoke-TabCommand -ArgList @('rename','WTCC USER')
Invoke-KeyCommand -ArgList @('enter')
Invoke-PaneCommand -ArgList @('exec','cls')

# 新規タブ（色付き）
Invoke-TabCommand -ArgList @('new','--tabColor','#330033')
Start-Sleep -Milliseconds 1000

# 新タブ側の初期化と分割・色・リサイズ
Invoke-PaneCommand -ArgList @('bg','#1A0000')
Invoke-PaneCommand -ArgList @('exec','cls')
Invoke-PaneCommand -ArgList @('split','vertical')
Invoke-PaneCommand -ArgList @('exec','cls')
Invoke-PaneCommand -ArgList @('bg','#001A00')
Invoke-PaneCommand -ArgList @('resize','right','2')
Invoke-PaneCommand -ArgList @('split','horizontal')
Invoke-PaneCommand -ArgList @('bg','#00001A')
Invoke-PaneCommand -ArgList @('resize','down','3')
Invoke-PaneCommand -ArgList @('exec','cls')

# タブ名変更の表示とリネーム
Invoke-PaneCommand -ArgList @('exec','echo "タブ名を変更する..."')
Invoke-TabCommand -ArgList @('rename','TEST USER')
Start-Sleep -Milliseconds 1000

# 完了メッセージ
Invoke-PaneCommand -ArgList @('exec','echo "ターミナル設定完了"')

