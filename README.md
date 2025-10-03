# WTCC (Windows Terminal Cockpit Customizer)

- 仕様: `docs/windows_terminal_spec.md`
- 設計: `docs/windows_terminal_design.md`

## 実行手順（builder.ps1 方式）

WTCC は「キーボードエミュレーションで Windows Terminal を組み立てる」ツールだよ。実行の流れは `wtcc.ps1` → `builder.ps1`。

```
# いちばん簡単（カレントの builder.ps1 を使う）
pwsh -ExecutionPolicy Bypass -File .\wtcc.ps1

# キー送出間隔を変えたい時（ミリ秒）
pwsh -ExecutionPolicy Bypass -File .\wtcc.ps1 -Interval 500
```

- `wtcc.ps1` は Windows Terminal を新規タブで起動し、`scripts/helpers.psm1` を読み込んでから `builder.ps1` を実行するエントリポイント。
- 旧 `script.txt` は廃止。互換のため `-ScriptPath` パラメータは残ってるけど未使用だよ。

### 事前に知ってほしい注意点

- 実行中はアクティブウィンドウにキーボードを送り続けるから、マウスや他アプリを触らないこと。
- `settings.json` の `"windowingBehavior": "useExisting"` 次第では新規タブが別ウィンドウに出ることがある。
- Windows Terminal のバージョンやロケールでコマンド名が違う場合がある。`wt_commands_map.json` で調整できる。

## builder.ps1 の書き方サンプル

`builder.ps1` は PowerShell で手順を書くよ。主要コマンドは `Invoke-WindowCommand` / `Invoke-PaneCommand` / `Invoke-TabCommand` / `Invoke-KeyCommand`。

```powershell
# ウィンドウサイズ変更
Invoke-WindowCommand -ArgList @('size','2000','1000')

# ペイン装飾・分割・移動・実行
Invoke-PaneCommand -ArgList @('bg','#440011')
Invoke-PaneCommand -ArgList @('split','horizontal')
Invoke-PaneCommand -ArgList @('exec','cd ~; cls')
Invoke-PaneCommand -ArgList @('move','up','1')

# タブ操作とキー送出
Invoke-TabCommand -ArgList @('rename','WTCC USER')
Invoke-KeyCommand -ArgList @('enter*2')

# 新規タブ（色付き）
Invoke-TabCommand -ArgList @('new','--tabColor','#330033')
```

より詳しい実装例はこのリポジトリ直下の `builder.ps1` を見てね。

## 旧方式（script.txt）からの移行メモ

- 例: `tab rename MySession` → `Invoke-TabCommand -ArgList @('rename','MySession')`
- 例: `pane bg #000000` → `Invoke-PaneCommand -ArgList @('bg','#000000')`
- 例: `pane split vertical` → `Invoke-PaneCommand -ArgList @('split','vertical')`
- 例: `window size 1200 800` → `Invoke-WindowCommand -ArgList @('size','1200','800')`
- 例: `key send enter*2` → `Invoke-KeyCommand -ArgList @('enter*2')`

`pane exec` は複数コマンドを `;` で繋げば順番に実行できるよ（例: `Invoke-PaneCommand -ArgList @('exec','cd C:\\P; git status; cls')`）。

## トラブルシュートのヒント

- タブ名変更やペイン分割はコマンドパレットに依存する場面があるため、ロケール/WTバージョン差でズレたら `wt_commands_map.json` を編集してね。
- 実行が速すぎる/遅すぎると感じたら `-Interval` を調整してみて。環境差で最適値が変わるよ。
- 実行途中で別ウィンドウをアクティブにすると、そっちに入力が飛ぶから注意！
