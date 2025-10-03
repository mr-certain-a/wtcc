<#
  WTCC builder.ps1
  - 旧 script.txt の手順を PowerShell コマンド化したビルダー本体
  - 依存: 同一ディレクトリの `wtcc.ps1` からロードされる `scripts/helpers.psm1`
  - 前提: `wtcc.ps1` 側で `Set-WTCCInterval` 済み＆WT が起動・アクティブになっていること
#>

# ウィンドウサイズ変更
Invoke-WindowCommand -ArgList @('size','2000','1000')

# 最初のペイン装飾・分割（アクションを直接呼び出し）
$split = Join-Path $PSScriptRoot 'scripts/actions/split.ps1'
$setbg = Join-Path $PSScriptRoot 'scripts/actions/set-bg.ps1'
$resize = Join-Path $PSScriptRoot 'scripts/actions/resize.ps1'

# 背景色 → 分割 → 背景色
Invoke-PaneCommand -ArgList @('exec', ("powershell -NoProfile -ExecutionPolicy Bypass -File '{0}' -Color '#440011'" -f $setbg))
Invoke-PaneCommand -ArgList @('exec', ("powershell -NoProfile -ExecutionPolicy Bypass -File '{0}' -Mode horizontal" -f $split))
Invoke-PaneCommand -ArgList @('exec', ("powershell -NoProfile -ExecutionPolicy Bypass -File '{0}' -Color '#111122'" -f $setbg))
Invoke-PaneCommand -ArgList @('exec','cd ~')
Invoke-PaneCommand -ArgList @('exec','cls')
Invoke-PaneCommand -ArgList @('move','up','1')

# サイズ調整＆初期化（resize.ps1 を直接呼ぶ）
Invoke-PaneCommand -ArgList @('exec', ("powershell -NoProfile -ExecutionPolicy Bypass -File '{0}' -Direction down -Count 2" -f $resize))
Invoke-PaneCommand -ArgList @('exec','cd ~')
Invoke-PaneCommand -ArgList @('exec','cls')

# さらに分割して背景色（直接呼び出し）
Invoke-PaneCommand -ArgList @('exec', ("powershell -NoProfile -ExecutionPolicy Bypass -File '{0}' -Mode vertical" -f $split))
Invoke-PaneCommand -ArgList @('exec', ("powershell -NoProfile -ExecutionPolicy Bypass -File '{0}' -Color '#004411'" -f $setbg))

# タブ名とキー送出、軽く掃除
Invoke-TabCommand -ArgList @('rename','WTCC USER')
Invoke-KeyCommand -ArgList @('enter')
Invoke-PaneCommand -ArgList @('exec','cls')

# 新規タブ（色付き）
Invoke-TabCommand -ArgList @('new','--tabColor','#330033')
Start-Sleep -Milliseconds 1000

# 新タブ側の初期化と分割・色・リサイズ
Invoke-PaneCommand -ArgList @('exec', ("powershell -NoProfile -ExecutionPolicy Bypass -File '{0}' -Color '#1A0000'" -f $setbg))
Invoke-PaneCommand -ArgList @('exec','cls')
Invoke-PaneCommand -ArgList @('exec', ("powershell -NoProfile -ExecutionPolicy Bypass -File '{0}' -Mode vertical" -f $split))
Invoke-PaneCommand -ArgList @('exec','cls')
Invoke-PaneCommand -ArgList @('exec', ("powershell -NoProfile -ExecutionPolicy Bypass -File '{0}' -Color '#001A00'" -f $setbg))
Invoke-PaneCommand -ArgList @('exec', ("powershell -NoProfile -ExecutionPolicy Bypass -File '{0}' -Direction right -Count 2" -f $resize))
Invoke-PaneCommand -ArgList @('exec', ("powershell -NoProfile -ExecutionPolicy Bypass -File '{0}' -Mode horizontal" -f $split))
Invoke-PaneCommand -ArgList @('exec', ("powershell -NoProfile -ExecutionPolicy Bypass -File '{0}' -Color '#00001A'" -f $setbg))
Invoke-PaneCommand -ArgList @('exec', ("powershell -NoProfile -ExecutionPolicy Bypass -File '{0}' -Direction down -Count 3" -f $resize))
Invoke-PaneCommand -ArgList @('exec','cls')

# タブ名変更の表示とリネーム
Invoke-PaneCommand -ArgList @('exec','echo "タブ名を変更する..."')
Invoke-TabCommand -ArgList @('rename','TEST USER')
Start-Sleep -Milliseconds 1000

# 完了メッセージ
Invoke-PaneCommand -ArgList @('exec','echo "ターミナル設定完了"')
