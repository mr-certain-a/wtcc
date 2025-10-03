# Windows Terminal 状態設定プログラム 設計書

## 🎯 目的
- PowerShell スクリプト上で Windows API (`user32.dll`) を呼び出し、  
  キーボードイベントのエミュレーションによって Windows Terminal を自動制御する。  
- スクリプト本体は **CUI的な制御を優先**し、GUI依存のマウス座標操作は避ける。  
- 構成は拡張性を重視し、新しいコマンドを関数追加で容易に取り込める。  

---

## 🏗️ 全体構成

### スクリプト構成
```
setup.ps1
 ├─ Keyboard.cs (C# inline定義: SendInput実装)
 ├─ Invoke-CommandLine 関数 (1行をパースして分岐)
 ├─ Invoke-TabCommand   関数 (タブ操作)
 ├─ Invoke-PaneCommand  関数 (ペイン操作)
 ├─ Invoke-WindowCommand関数 (ウィンドウ操作)
 └─ Send-Key / Send-KeyCombo / Send-Text ユーティリティ
```

---

## 🧩 各モジュール設計

### 1. .NET 組み込み (キーボードエミュレーション)
- PowerShell の `Add-Type` で C# コードをインライン定義  
- 利用 API: `user32.dll` の `SendInput`  
- 機能:
  - `KeyDown(short vk)`  
  - `KeyUp(short vk)`  
  - `KeyPress(short vk)`  

これにより仮想キーコード (VK) を発行可能にする。  

---

### 2. ユーティリティ関数
- `Send-Key <VK>`  
  - 単発キーを送信 → Interval待ち  
- `Send-KeyCombo <VK[]>`  
  - 複数キーを押下 → Interval → 順次キーアップ  
- `Send-Text <string>`  
  - 文字列を 1文字ずつ KeyPress  
  - 最後に `Enter` を送信するかは呼び出し側で制御  

---

### 3. ディスパッチャ
- 関数: `Invoke-CommandLine($line)`  
- 処理:
  1. コメント・空行スキップ  
  2. スペースで分割 (`$parts`)  
  3. `$parts[0]` を大分類コマンド (`tab`/`pane`/`window`)  
  4. サブコマンド＋引数を配列で渡す  

---

### 4. TabCommand
- `tab new` → `Ctrl+Shift+T`  
- `tab rename NAME` → コマンドパレット呼び出し後、名前入力＋Enter  
- `tab color COLOR` → コマンドパレット呼び出し後、色設定操作  

> 注：`rename` と `color` は Windows Terminal の「コマンドパレット（Ctrl+Shift+P）」経由で処理  
> - コマンドパレット呼び出し  
> - 目的のコマンド名を文字入力  
> - Enter確定  
> - 必要なら続けて引数入力  

---

### 5. PaneCommand
- `pane split vertical/horizontal`  
  - `Alt+Shift+D` による分割  
  - Windows Terminal 側の設定依存で方向指定を工夫  
- `pane move <dir> <count>`  
  - Shift+Alt+矢印キーを指定回数送信  
- `pane bg #RRGGBB`  
  - ANSI/OSC 11 を送って背景色を直接変更  
- `pane exec <COMMAND...>`  
  - 文字列を `Send-Text` で流し込み  
  - `;` 区切りで複数コマンドも展開し、順番に送信  

---

### 6. WindowCommand
- `window size <W> <H>`  
  - Win32 API (`FindWindow`, `MoveWindow`) を利用  
  - Terminal ウィンドウのハンドルを取得し、固定値でリサイズ  

---

## ⚙️ 設定値
- **Interval**: デフォルト 500ms  
  - 引数 `-Interval` で上書き可能  
  - 全てのキー送信の間隔に適用  

---

## 🔮 拡張設計
- **状態ダンプ機能**  
  - `settings.json` の読み込み → プロファイル情報反映  
  - `UIAutomation` によるウィンドウ内タブ／ペイン数の推定  
  - 取得した情報を「手順ファイル」として吐き出し、再現性を高める  

---

## 💡 設計の要点
1. **.NET の SendInput を中核に据える**  
2. **ディスパッチ方式でコマンドを整理**  
3. **操作は基本キーボードのみ**（マウス座標依存は排除）  
4. **拡張を前提**に関数分割し、将来の状態ダンプ機能にも備える  
