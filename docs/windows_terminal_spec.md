# Windows Terminal 状態設定プログラム 仕様書

- この一連のプロジェクトの名称を以下のように定める。

​	正式名称: Windows Terminal Cockpit Customizer

​	略称: WTCC

- プロジェクトのカレントフォルダは ./WTCC とする。

  フォルダ構成は以下を基本とする。必要に応じて追加・調整していくものとする。

  WTCC/ - プロジェクトルート
   ├─ docs/ - ドキュメント
   │  ├─ windows_terminal_spec.md
   │  └─ windows_terminal_design.md
   ├─ scripts/ - PowerShellスクリプト・モジュール群（必要に応じて追加）
   │  ├─ wtcc.ps1 - エントリーポイント
   │  └─ helpers.psm1
   └─ README.md

  GitはWTCCの親フォルダ（codex起動時のカレント）と一緒の管理。

## 概要

Windows Terminal を自動制御し、あらかじめ定義した手順ファイルに基づいてタブやペインの状態を再現するスクリプト。  
ユーザーは手順ファイルを編集するだけでレイアウト・色・初期化コマンドなどを再生できる。  

## 実行方法
```powershell
.\setup.ps1 -ScriptFile script.txt -Interval 500
```

- `-ScriptFile` : 実行する手順ファイル (必須)  
- `-Interval`   : キー送信の待機時間(ms)。既定値は 500  

---

## 手順ファイル仕様

### 基本ルール
- テキスト形式（UTF-8推奨）  
- 空行は無視  
- `#` で始まる行はコメントとして無視  
- 各行は以下の形式：  
  ```
  <大分類> <サブコマンド> [引数...]
  ```

---

### コマンド一覧

#### **tab**
- `tab new`  
  新しいタブを開く（Ctrl+Shift+T）  

- `tab rename <NAME>`  
  タブの名前を変更  

- `tab color <COLOR>`  
  タブのタイトルバー色を変更  

注: `tab rename`/`tab color` はコマンドパレット経由で実行します。Windows Terminal のバージョンやロケールでコマンド名が異なるため、`wt_commands_map.json` の `rename-tab` にバージョン別（1.22系=「タブ名を変更」、1.21系=「[名前の変更] タブ」）やローカライズ名を設定できます。

---

#### **pane**
- `pane split vertical`  
  ペインを縦に分割  

- `pane split horizontal`  
  ペインを横に分割  

- `pane move <direction> <count>`  
  ペインをリサイズ  
  - `<direction>` = `left|right|up|down`  
  - `<count>` = 繰り返し回数  
  - 例：`pane move right 3` → Shift+Alt+→ を3回送信  

- `pane bg <#RRGGBB>`  
  ペイン背景色を変更（ANSI/OSC 11で直接設定）  

- `pane exec <COMMAND...>`  
  カレントペインに任意のコマンドを送信してEnter実行  
  - 行末までをコマンド文字列として扱う  
  - `;` 区切りで複数コマンドを指定可能  
  - 例：  
    ```
    pane exec cd C:\Projects
    pane exec cd C:\Proj; git pull; .venv\Scripts\activate.ps1
    ```

---

#### **window**
- `window size <WIDTH> <HEIGHT>`  
  ターミナルウィンドウ全体のサイズを固定値で変更  

---

#### **key / key-send**
- `key send <KEY[ *COUNT]> [KEY ...]`  
  キー入力を送出（例: `enter`, `tab`, `space`, `esc`）。`name*N` で同じキーをN回送出。  
  例: `key send enter`, `key-send tab space`, `key send enter*2`  

---

## 使用例

### script.txt
```
# 新しいタブを作成し、名前と色を設定
tab new
tab rename MySession
tab color blue

# ペイン操作
pane split vertical
pane move right 3
pane bg #000000

# 初期化コマンド
pane exec cd C:\Projects
pane exec git status
pane exec .venv\Scripts\activate.ps1

# ウィンドウサイズを変更
window size 1200 800
```

---

## 将来的な拡張予定
- 現在のターミナル状態を読み取り、可能な範囲で手順ファイルを自動生成する機能  
- `settings.json` の解析によるプロファイル情報取り込み  
- UIAutomation を利用したより精密な状態把握  
