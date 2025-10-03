# WTCC (Windows Terminal Cockpit Customizer)

WTCCは、Windows Terminalを“手で操作するノリ”で自動構築しちゃうツールだよ。キーボード入力をエミュって、タブ/ペインの分割・移動・サイズ変更・背景色・コマンド投入、新規タブ作成、さらに settings.json のプロファイル追加までイケる。

- 仕様: `docs/windows_terminal_spec.md`（旧script.txt仕様・いまは参考アーカイブ）
- 設計: `docs/windows_terminal_design.md`

## できること

- ペイン操作の自動化（分割・移動・リサイズ・背景色・任意コマンド送信）
- 新規タブ作成（`wt`の引数文字列を“そのまま”渡せる）
- settings.json にプロファイル追加（同名があればスキップ。背景/アイコンのファイル名はリポジトリ内パスに自動展開）

## 使い方（builder.ps1 方式）

実行の流れは `wtcc.ps1` → `builder.ps1`。WTを新規タブで起動→ビルダーが手順を流す感じ。

```
# かんたん実行（カレントの builder.ps1 を使う）
pwsh -ExecutionPolicy Bypass -File .\wtcc.ps1

# キー送出間隔を変えたい時（ミリ秒）
pwsh -ExecutionPolicy Bypass -File .\wtcc.ps1 -Interval 500
```

- `wtcc.ps1` は `scripts/helpers.psm1` を読み込み後、`builder.ps1` を実行するエントリポイント。
- 旧 `script.txt` は完全廃止（互換オプションも無し）。

### 注意点

- 実行中は“前面ウィンドウ”にキーが飛ぶから、マウス/他アプリ操作は控えてね。
- `settings.json` の `"windowingBehavior": "useExisting"` 次第で、新規タブが別ウィンドウに出ることがある。
- タブ名変更など一部はWTのロケール/バージョン差の影響を受けることがある。必要なら `wt_commands_map.json` を調整してね。

## builder.ps1 の基本レシピ

`builder.ps1`ではユーティリティ関数をモジュールとして読み込んで使うのが基本スタイル。

- ペイン系（プロセス新規起動なしの直接実行）
  - Import-Module `scripts/actions/PaneActions.psm1` -DisableNameChecking
  - 提供関数: `Pane-Split` / `Pane-SetBg` / `Pane-Resize` / `Pane-Move` / `Pane-Exec` / `Pane-ExecMany`

- タブ系（wt引数を“そのまま”文字列で渡す）
  - Import-Module `scripts/actions/TabActions.psm1` -DisableNameChecking
  - 提供関数: `Tab-Create "--tabColor '#330033' -p 'xumi'"`

- プロファイル追加（settings.json直編集）
  - Import-Module `scripts/actions/ProfileActions.psm1` -DisableNameChecking
  - 提供関数: `Profile-Add -Name 'XUMI' -RawJson '"opacity":70, ...'`

### 例（抜粋）

```powershell
# ウィンドウサイズ変更（helpersのWindowコマンド）
Invoke-WindowCommand -ArgList @('size','2000','1000')

# モジュール読み込み（未承認動詞の警告は -DisableNameChecking で抑制）
Import-Module -Force -Scope Local -Name (Join-Path $PSScriptRoot 'scripts/actions/PaneActions.psm1') -DisableNameChecking
Import-Module -Force -Scope Local -Name (Join-Path $PSScriptRoot 'scripts/actions/TabActions.psm1') -DisableNameChecking
Import-Module -Force -Scope Local -Name (Join-Path $PSScriptRoot 'scripts/actions/ProfileActions.psm1') -DisableNameChecking

# ペイン: 色 → 分割 → 色 → カレント変更/クリア → 移動/リサイズ
Pane-SetBg '#440011'
Pane-Split 'horizontal'
Pane-SetBg '#111122'
Pane-ExecMany @('cd ~','cls')
Pane-Move 'up' 1
Pane-Resize 'down' 2

# タブ: wtの引数をそのまま文字列で渡す
Tab-Create "--tabColor '#330033' -p 'xumi'"

# プロファイル追加（同名があればスキップ）
Profile-Add -Name 'XUMI' -RawJson '
  "opacity": 70,
  "startingDirectory": "G:\\XUMI",
  "useAcrylic": true,
  "backgroundImage": "xumi_sofa.png",              # ./images を自動展開
  "backgroundImageOpacity": 0.15,
  "backgroundImageStretchMode": "uniformToFill",
  "icon": "3dicons-bulb-dynamic-color.png",         # ./icons を自動展開
  "suppressApplicationTitle": true,
  "commandline": "C:\\Program Files\\PowerShell\\7\\pwsh.exe"
'

# タブ名変更と軽く掃除（helpersの既存関数）
Invoke-TabCommand -ArgList @('rename','WTCC USER')
Invoke-KeyCommand -ArgList @('enter')
Pane-Exec 'cls'
```

より詳しい流れはリポジトリ直下の `builder.ps1` を見てね。

## 旧方式（script.txt）からの移行メモ

- 分割/移動/リサイズ/背景色: 旧 `Invoke-PaneCommand` の細分岐は廃止 → いまは `Pane-*` 関数でやる
- 新規タブ作成: 旧 `Invoke-TabCommand -ArgList @('new',...)` → いまは `Tab-Create "<wtの引数>"`
- 任意コマンド送信: 旧 `pane exec ...` → いまは `Pane-Exec` / `Pane-ExecMany`
- タブ名変更: そのまま `Invoke-TabCommand -ArgList @('rename','...')`
- ウィンドウサイズ: そのまま `Invoke-WindowCommand -ArgList @('size','W','H')`

## トラブルシュートのヒント

- ロケール/WTバージョン差でコマンド名が違う時は、`wt_commands_map.json` を調整（特にタブ名変更）。
- 動きが速すぎ/遅すぎなら `-Interval` をチューニング。
- 実行中に他ウィンドウへフォーカス移すと、そっちに入力が飛ぶから注意！

