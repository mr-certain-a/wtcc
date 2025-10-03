# WTCC (Windows Terminal Cockpit Customizer)

- 仕様: `docs/windows_terminal_spec.md`
- 設計: `docs/windows_terminal_design.md`

## 使い方

```
# 全てデフォルトで実行（カレントの script.txt が読み込まれる）
./wtcc.ps1

# 例: script.txt を500ms間隔で再生
powershell -ExecutionPolicy Bypass -File .\WTCC\wtcc.ps1 -ScriptPath .\script.txt -Interval 500
```

`WTCC/scripts/wtcc.ps1` は薄いラッパーで、`WTCC/wtcc.ps1` を呼び出すだけ。

## 手順ファイルサンプル

```
# 新しいタブを作成し、名前と色を設定
tab new
tab rename MySession
tab color blue

# ペイン操作
pane split vertical
pane resize right 3
pane bg #000000
pane move left

# 初期化コマンド
pane exec cd C:\\Projects
pane exec git status
pane exec .venv\\Scripts\\activate.ps1

# キー送出の例（Enter を2回）
key send enter*2

# ウィンドウサイズを変更
window size 1200 800
```

注意: `tab color` と `split vertical/horizontal` はコマンドパレット経由の検索文字列で実行します。ターミナルの表示言語や設定・バージョンによりコマンド名が異なる場合があります。`wt_commands_map.json` でローカライズ・バージョン別の文字列を定義できます（例: `rename-tab` は WT 1.22系で「タブ名を変更」、1.21系で「[名前の変更] タブ」）。`pane bg` はANSI/OSC 11で直接色コードを送るためロケール非依存です。
