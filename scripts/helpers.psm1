<#
  WTCC helpers.psm1
  - キーボードエミュレーション（SendInput）
  - 文字列送信ユーティリティ
  - ウィンドウサイズ変更
  - コマンドディスパッチャ
#>

$script:WTCC_Interval = 500
$script:WTCC_WTMap = $null
$script:WTCC_WTVersion = $null

function Get-WTCCWTVersion {
    if ($null -ne $script:WTCC_WTVersion -and -not [string]::IsNullOrWhiteSpace([string]$script:WTCC_WTVersion)) {
        return $script:WTCC_WTVersion
    }
    try {
        # 環境変数で上書き可能（CI等想定）
        $envVer = [string]$env:WTCC_WT_VERSION
        if (-not [string]::IsNullOrWhiteSpace($envVer)) {
            $script:WTCC_WTVersion = $envVer
            return $script:WTCC_WTVersion
        }
        # 複数結果がある場合（複数利用者/アーキ/プレビュー等）に備えて最大バージョンを採用
        $pkgs = Get-AppxPackage -Name 'Microsoft.WindowsTerminal*' -ErrorAction Stop | Sort-Object -Property Version -Descending
        if ($pkgs -and $pkgs.Count -ge 1) {
            $script:WTCC_WTVersion = [string]$pkgs[0].Version
            Write-WTCCLog ("WT versions found: {0}; use={1}" -f (($pkgs | ForEach-Object { $_.Version }) -join ', '), $script:WTCC_WTVersion) 'DBG'
            return $script:WTCC_WTVersion
        }
    } catch {
        Write-WTCCLog "WT バージョン取得に失敗: $($_.Exception.Message)" 'ERR'
    }
    $script:WTCC_WTVersion = ''
    return $script:WTCC_WTVersion
}

function Get-WTCCWTCommand {
    param(
        [Parameter(Mandatory)][string]$Key,
        [string]$Default
    )
    try {
        if ($null -eq $script:WTCC_WTMap) {
            $mapPath = Join-Path $PSScriptRoot '..\wt_commands_map.json'
            if (Test-Path -LiteralPath $mapPath) {
                $json = Get-Content -LiteralPath $mapPath -Raw -Encoding UTF8
                $script:WTCC_WTMap = ConvertFrom-Json -InputObject $json -AsHashtable
            } else {
                $script:WTCC_WTMap = @{}
            }
        }
        $entry = $script:WTCC_WTMap[$Key]
        if ($null -ne $entry) {
            # 形式A: 文字列 → そのまま
            if ($entry -is [string]) {
                $s = [string]$entry
                if (-not [string]::IsNullOrWhiteSpace($s)) { return $s }
            }
            # 形式B: 配列 → 末尾（優先）
            elseif ($entry -is [System.Array]) {
                $cands = @()
                foreach ($x in $entry) { if (-not [string]::IsNullOrWhiteSpace($x)) { $cands += [string]$x } }
                if ($cands.Count -gt 0) { return $cands[-1] }
            }
            # 形式C: ハッシュ（バージョン/デフォルト対応）
            elseif ($entry -is [hashtable]) {
                $ver = Get-WTCCWTVersion
                $verPrefix = ''
                try {
                    if (-not [string]::IsNullOrWhiteSpace($ver)) {
                        $v = [version]$ver
                        $verPrefix = ('{0}.{1}' -f $v.Major, $v.Minor)
                    }
                } catch { $verPrefix = '' }

                $picked = $null
                if ($entry.ContainsKey('byVersion')) {
                    $byv = $entry['byVersion']
                    if ($byv -is [hashtable]) {
                        # 優先度: Major.Minor の完全一致 > 先頭一致のうち最長一致
                        $picked = $null
                        if (-not [string]::IsNullOrWhiteSpace($verPrefix) -and $byv.ContainsKey($verPrefix)) {
                            $picked = $byv[$verPrefix]
                        } else {
                            $best = $null; $bestLen = -1
                            foreach ($k in $byv.Keys) {
                                $kv = [string]$k
                                if ([string]::IsNullOrWhiteSpace($kv)) { continue }
                                if (-not [string]::IsNullOrWhiteSpace($ver) -and $ver.StartsWith($kv)) {
                                    if ($kv.Length -gt $bestLen) { $best = $byv[$k]; $bestLen = $kv.Length }
                                }
                            }
                            if ($best -ne $null) { $picked = $best }
                        }
                    }
                }
                if ($null -eq $picked -and $entry.ContainsKey('default')) { $picked = $entry['default'] }

                if ($null -ne $picked) {
                    if ($picked -is [string]) { $s=[string]$picked; if (-not [string]::IsNullOrWhiteSpace($s)) { return $s } }
                    elseif ($picked -is [System.Array]) {
                        $cands = @(); foreach ($x in $picked) { if (-not [string]::IsNullOrWhiteSpace($x)) { $cands += [string]$x } }
                        if ($cands.Count -gt 0) { return $cands[-1] }
                    }
                }
            }
        }
    } catch {
        Write-WTCCLog "WTコマンドマップ取得に失敗: $($_.Exception.Message)" 'ERR'
    }
    return $Default
}

function Quote-PSLiteral {
    param([string]$Text)
    if ($null -eq $Text) { return "''" }
    return "'" + ($Text -replace "'", "''") + "'"
}

function Split-WTCCTokens {
    param([Parameter(Mandatory)][string]$Text)
    $tokens = New-Object System.Collections.Generic.List[string]
    $buf = New-Object System.Text.StringBuilder
    $inS = $false; $inD = $false
    for ($i=0; $i -lt $Text.Length; $i++) {
        $ch = $Text[$i]
        if (-not $inS -and -not $inD) {
            if ([char]::IsWhiteSpace($ch)) {
                if ($buf.Length -gt 0) { $tokens.Add($buf.ToString()); $buf.Clear() | Out-Null }
                continue
            }
            if ($ch -eq "'") { $inS = $true; continue }
            if ($ch -eq '"') { $inD = $true; continue }
            [void]$buf.Append($ch)
        } elseif ($inS) {
            if ($ch -eq "'") { $inS = $false; continue }
            [void]$buf.Append($ch)
        } else { # inD
            if ($ch -eq '"') { $inD = $false; continue }
            [void]$buf.Append($ch)
        }
    }
    if ($buf.Length -gt 0) { $tokens.Add($buf.ToString()) }
    return ,$tokens.ToArray()
}

function Ensure-WTCCWinForms {
    try { $null = [System.Windows.Forms.SendKeys] } catch { Add-Type -AssemblyName System.Windows.Forms -ErrorAction Stop }
}

function Send-AltShiftKey {
    param([Parameter(Mandatory)][string]$Token)
    Enter-WTCCFunc -Name 'Send-AltShiftKey' -Params @{ Token = $Token }
    Ensure-WTCCWinForms
    $pattern = "%+{" + $Token + "}"
    [System.Windows.Forms.SendKeys]::SendWait($pattern)
    if ($script:WTCC_Interval -gt 0) { Start-Sleep -Milliseconds $script:WTCC_Interval }
    Exit-WTCCFunc -Name 'Send-AltShiftKey'
}

# --- デバッグロギング -------------------------------------------------------
function Test-WTCCDebug {
    $val = [string]$env:WTCC_DEBUG
    if ([string]::IsNullOrWhiteSpace($val)) { return $false }
    return ($val -match '^(?i:true|1|yes|on)$')
}

function Convert-WTCCParamString {
    param([object]$Value)
    try {
        if ($null -eq $Value) { return 'null' }
        $s = [string]$Value
        if ($s.Length -gt 80) { return ($s.Substring(0,80) + "…($($s.Length))") }
        return $s
    } catch { return '<unprintable>' }
}

function Write-WTCCLog {
    param([string]$Message, [string]$Category = 'DBG')
    if (-not (Test-WTCCDebug)) { return }
    $ts = (Get-Date).ToString('HH:mm:ss.fff')
    Write-Host "[WTCC][$Category][$ts] $Message" -ForegroundColor DarkGray
}

function Enter-WTCCFunc {
    param([string]$Name, [hashtable]$Params)
    if (-not (Test-WTCCDebug)) { return }
    $items = foreach ($k in ($Params.Keys | Sort-Object)) { '{0}={1}' -f $k,(Convert-WTCCParamString $Params[$k]) }
    $joined = ($items -join ', ')
    Write-WTCCLog (">> {0}({1})" -f $Name, $joined) 'IN'
}

function Exit-WTCCFunc {
    param([string]$Name, [object]$Result)
    if (-not (Test-WTCCDebug)) { return }
    $out = if ($PSBoundParameters.ContainsKey('Result')) { " : $(Convert-WTCCParamString $Result)" } else { '' }
    Write-WTCCLog "<< $Name$out" 'OUT'
}

function Set-WTCCInterval {
    param([int]$Interval)
    Enter-WTCCFunc -Name 'Set-WTCCInterval' -Params @{ Interval = $Interval }
    $script:WTCC_Interval = [Math]::Max(0, $Interval)
    Exit-WTCCFunc -Name 'Set-WTCCInterval' -Result $script:WTCC_Interval
}

Add-Type @"
using System;
using System.Runtime.InteropServices;

// keybd_event ベースの WTCC_Keyboard 実装（拡張キー対応）
public static class WTCC_Keyboard {
    const uint KEYEVENTF_KEYUP       = 0x0002;
    const uint KEYEVENTF_EXTENDEDKEY = 0x0001;
    const uint MAPVK_VK_TO_VSC       = 0;

    [DllImport("user32.dll", SetLastError = true)]
    static extern void keybd_event(byte bVk, byte bScan, uint dwFlags, UIntPtr dwExtraInfo);

    [DllImport("user32.dll")]
    static extern ushort VkKeyScanW(char ch);

    [DllImport("user32.dll")]
    static extern uint MapVirtualKeyW(uint uCode, uint uMapType);

    static byte Scan(byte vk) { return (byte)MapVirtualKeyW(vk, MAPVK_VK_TO_VSC); }

    // 最低限の拡張キー判定
    static bool IsExtended(byte vk) {
        switch (vk) {
            case 0x21: // PgUp
            case 0x22: // PgDn
            case 0x23: // End
            case 0x24: // Home
            case 0x25: // Left
            case 0x26: // Up
            case 0x27: // Right
            case 0x28: // Down
            case 0x2D: // Insert
            case 0x2E: // Delete
            case 0x6F: // NumPad Divide
            case 0x90: // NumLock
            case 0xA3: // RCtrl
            case 0xA5: // RAlt
                return true;
            default:
                return false;
        }
    }

    static void Send(byte vk, bool up) {
        byte scan = Scan(vk);
        uint flags = 0;
        if (IsExtended(vk)) flags |= KEYEVENTF_EXTENDEDKEY;
        if (up)            flags |= KEYEVENTF_KEYUP;
        keybd_event(vk, scan, flags, UIntPtr.Zero);
    }

    public static void KeyDown(short vk) { Send((byte)vk, false); }
    public static void KeyUp  (short vk) { Send((byte)vk, true ); }

    public static void KeyPress(short vk, int delayMs) {
        KeyDown(vk);
        if (delayMs > 0) System.Threading.Thread.Sleep(delayMs);
        KeyUp(vk);
    }

    // VkFromChar / SendUnicode / Key*Scan は未使用のため削除済み
}
"@

# --- VK マップ（最低限） ---
$script:_VK = @{
    'CTRL' = 0x11; 'SHIFT' = 0x10; 'ALT' = 0x12;
    'ENTER' = 0x0D; 'TAB' = 0x09; 'ESC' = 0x1B; 'SPACE' = 0x20;
    'P' = 0x50; 'T' = 0x54; 'D' = 0x44;
    'LEFT' = 0x25; 'UP' = 0x26; 'RIGHT' = 0x27; 'DOWN' = 0x28;
}

function Send-Key {
    param([Parameter(Mandatory)][int]$VK)
    Enter-WTCCFunc -Name 'Send-Key' -Params @{ VK = $VK }
    $delay = [Math]::Max(1, $script:WTCC_Interval)
    $kp2 = [WTCC_Keyboard].GetMethod('KeyPress', [Type[]]@([int16],[int32]))
    if ($kp2) {
        [WTCC_Keyboard]::KeyPress([short]$VK, $delay)
    } else {
        $kp1 = [WTCC_Keyboard].GetMethod('KeyPress', [Type[]]@([int16]))
        if ($kp1) {
            [WTCC_Keyboard]::KeyPress([short]$VK)
            if ($delay -gt 0) { Start-Sleep -Milliseconds $delay }
        } else {
            [WTCC_Keyboard]::KeyDown([short]$VK)
            if ($delay -gt 0) { Start-Sleep -Milliseconds $delay }
            [WTCC_Keyboard]::KeyUp([short]$VK)
        }
    }
    Exit-WTCCFunc -Name 'Send-Key'
}

function Send-KeyCombo {
    param(
        [Parameter(Mandatory)][int[]]$VKs
    )
    Enter-WTCCFunc -Name 'Send-KeyCombo' -Params @{ VKs = ($VKs -join '+') }

    if (-not $VKs -or $VKs.Count -eq 0) { Exit-WTCCFunc -Name 'Send-KeyCombo'; return }

    # 修飾キー(CTRL/SHIFT/ALT) と 非修飾キー に分ける
    $mods = @()
    $keys = @()
    foreach ($vk in $VKs) {
        if ($vk -in 0x10,0x11,0x12) { $mods += $vk } else { $keys += $vk }
    }

    # 1) 修飾キーを素早く押し下げ（間にスリープを入れない or ごく短く）
    foreach ($m in $mods) {
        [WTCC_Keyboard]::KeyDown([short]$m)
    }
    if ($script:WTCC_Interval -gt 0) { Start-Sleep -Milliseconds ([Math]::Min(50, $script:WTCC_Interval)) }

    # 2) 非修飾キーを（必要なら複数）順番に押下→解放
    if ($keys.Count -gt 0) {
        foreach ($k in $keys) {
            [WTCC_Keyboard]::KeyDown([short]$k)
            if ($script:WTCC_Interval -gt 0) { Start-Sleep -Milliseconds ([Math]::Min(60, $script:WTCC_Interval)) }
            [WTCC_Keyboard]::KeyUp([short]$k)
            if ($script:WTCC_Interval -gt 0) { Start-Sleep -Milliseconds ([Math]::Min(60, $script:WTCC_Interval)) }
        }
    } else {
        # すべて修飾キーだけ、というケースはそのまま次へ（通常あまり無い）
        if ($script:WTCC_Interval -gt 0) { Start-Sleep -Milliseconds ([Math]::Min(60, $script:WTCC_Interval)) }
    }

    # 3) 修飾キーを逆順で解放
    for ($i = $mods.Count - 1; $i -ge 0; $i--) {
        [WTCC_Keyboard]::KeyUp([short]$mods[$i])
        if ($script:WTCC_Interval -gt 0) { Start-Sleep -Milliseconds ([Math]::Min(60, $script:WTCC_Interval)) }
    }

    Exit-WTCCFunc -Name 'Send-KeyCombo'
}

function Send-Text {
    param([Parameter(Mandatory)][string]$Text)
    Enter-WTCCFunc -Name 'Send-Text' -Params @{ Len = $Text.Length; Sample = ($Text.Substring(0,[Math]::Min(20,$Text.Length))) }

    # 1) 現在のクリップボードをバックアップ（失敗しても続行）
    $backup = $null
    try { $backup = Get-Clipboard -Raw -ErrorAction Stop } catch { $backup = $null }

    # 2) テキストをクリップボードへ。Set-Clipboard 失敗時はネイティブAPIでフォールバック
    $setOk = $false
    try {
        Set-Clipboard -Value $Text -AsPlainText -ErrorAction Stop
        $setOk = $true
    } catch {
        if (-not (Get-Command Ensure-WTCCClipboardType -ErrorAction SilentlyContinue)) {
            function Ensure-WTCCClipboardType {
                try { [void][WTCC_Clipboard] } catch {
Add-Type @"
using System;
using System.Runtime.InteropServices;
public static class WTCC_Clipboard {
    const uint CF_UNICODETEXT = 13;
    const uint GMEM_MOVEABLE = 0x0002;
    [DllImport("user32.dll", SetLastError=true)] static extern bool OpenClipboard(IntPtr hWndNewOwner);
    [DllImport("user32.dll", SetLastError=true)] static extern bool CloseClipboard();
    [DllImport("user32.dll", SetLastError=true)] static extern bool EmptyClipboard();
    [DllImport("user32.dll", SetLastError=true)] static extern IntPtr SetClipboardData(uint uFormat, IntPtr hMem);
    [DllImport("kernel32.dll", SetLastError=true)] static extern IntPtr GlobalAlloc(uint uFlags, UIntPtr dwBytes);
    [DllImport("kernel32.dll", SetLastError=true)] static extern IntPtr GlobalLock(IntPtr hMem);
    [DllImport("kernel32.dll", SetLastError=true)] static extern bool GlobalUnlock(IntPtr hMem);
    public static bool SetTextUnicode(string text) {
        string s = text ?? string.Empty;
        int byteLen = (s.Length + 1) * 2;
        IntPtr h = IntPtr.Zero; IntPtr ptr = IntPtr.Zero;
        try {
            h = GlobalAlloc(GMEM_MOVEABLE, (UIntPtr)(uint)byteLen);
            if (h == IntPtr.Zero) return false;
            ptr = GlobalLock(h);
            if (ptr == IntPtr.Zero) return false;
            var bytes = System.Text.Encoding.Unicode.GetBytes(s + "\0");
            Marshal.Copy(bytes, 0, ptr, bytes.Length);
            GlobalUnlock(h);
            if (!OpenClipboard(IntPtr.Zero)) return false;
            try {
                if (!EmptyClipboard()) return false;
                if (SetClipboardData(CF_UNICODETEXT, h) == IntPtr.Zero) return false;
                h = IntPtr.Zero; return true;
            } finally { CloseClipboard(); }
        } catch { return false; }
        finally {
            if (ptr != IntPtr.Zero) { try { GlobalUnlock(h); } catch {} }
            if (h != IntPtr.Zero) { try { Marshal.FreeHGlobal(h); } catch {} }
        }
    }
}
"@
                }
            }
        }
        Ensure-WTCCClipboardType
        $setOk = [WTCC_Clipboard]::SetTextUnicode($Text)
        if (-not $setOk) { Write-WTCCLog "クリップボードへの設定に失敗（Set-Clipboard/Win32ともに失敗）" 'ERR' }
    }

    if ($setOk) {
        # 3) Ctrl+V を送って貼り付け
        Send-KeyCombo @($script:_VK.CTRL, 0x56) # 'V'
        if ($script:WTCC_Interval -gt 0) { Start-Sleep -Milliseconds $script:WTCC_Interval }
    }

    # 4) クリップボードをリストア（文字列に戻す）
    try {
        if ($null -ne $backup) {
            Set-Clipboard -Value $backup -AsPlainText -ErrorAction Stop
        }
    } catch {
        if ($null -ne $backup) {
            try { Ensure-WTCCClipboardType } catch {}
            if (-not [WTCC_Clipboard]::SetTextUnicode([string]$backup)) {
                Write-WTCCLog "クリップボードの復元に失敗（Win32失敗）" 'ERR'
            }
        }
    }

    Exit-WTCCFunc -Name 'Send-Text'
}

function Invoke-CommandPalette {
    param([Parameter(Mandatory)][string]$Query,
          [string]$AfterText,
          [switch]$PressEnterAfterQuery,
          [switch]$PressEnterAfterText)
    Enter-WTCCFunc -Name 'Invoke-CommandPalette' -Params @{ Query = $Query; AfterLen = ($AfterText?.Length); QEnter = [bool]$PressEnterAfterQuery; TEnter = [bool]$PressEnterAfterText }

    Send-KeyCombo @($script:_VK.CTRL, $script:_VK.SHIFT, $script:_VK.P)
    Send-Text $Query
    if ($PressEnterAfterQuery) {
        # コマンド確定（例: Rename tab 実行）
        Send-Key $script:_VK.ENTER
        # 実行直後はフォーカスがフィールドに移るまで少し間がある。
        # ここで短い待機を入れないと、貼り付けの先頭がコンソールに落ちることがある。
        if ($AfterText) {
            $preDelay = [Math]::Max(200, [int]($script:WTCC_Interval * 2))
            Start-Sleep -Milliseconds $preDelay
        }
    }
    if ($AfterText) {
        # 貼り付け（Send-TextはCtrl+Vベース）
        # 念のため既存文字を全選択してから上書き（Ctrl+A）
        Send-KeyCombo @($script:_VK.CTRL, 0x41)  # Ctrl + A
        Send-Text $AfterText
        # 貼り付けの描画/確定に少し待ちを入れてからEnterで確定（従来の約2倍）
        if ($PressEnterAfterText) {
            $delay = [Math]::Max(100, [int]($script:WTCC_Interval * 2))
            Start-Sleep -Milliseconds $delay
            Send-Key $script:_VK.ENTER
        }
    } elseif ($PressEnterAfterText) {
        Send-Key $script:_VK.ENTER
    }
    Exit-WTCCFunc -Name 'Invoke-CommandPalette'
}

function Send-BackspaceBurst {
    param([int]$Count = 20)
    Enter-WTCCFunc -Name 'Send-BackspaceBurst' -Params @{ Count = $Count }
    $n = [Math]::Max(0, [int]$Count)
    for ($i = 0; $i -lt $n; $i++) { [WTCC_Keyboard]::KeyDown(0x08); [WTCC_Keyboard]::KeyUp(0x08) }
    Exit-WTCCFunc -Name 'Send-BackspaceBurst'
}

function Invoke-TabCommand {
    param([string[]]$ArgList)
    Enter-WTCCFunc -Name 'Invoke-TabCommand' -Params @{ Args = ($ArgList -join ' ') }
    if (-not $ArgList -or $ArgList.Count -lt 1) { return }
    switch -Regex ($ArgList[0]) {
        '^new$' {
            # 追加指定: tab new [--title <NAME>|title=<NAME>] [--tabColor <#RRGGBB>|tabColor=<#RRGGBB>|color=<#RRGGBB>]
            $title = $null; $color = $null
            for ($i = 1; $i -lt $ArgList.Count; $i++) {
                $tok = [string]$ArgList[$i]
                if ($tok -match '^(?:--title|title)=(.+)$') { $title = $Matches[1]; continue }
                if ($tok -match '^(?:--tabColor|tabColor|color)=(.+)$') { $color = $Matches[1]; continue }
                if ($tok -eq '--title' -and ($i+1) -lt $ArgList.Count) { $title = [string]$ArgList[++$i]; continue }
                if ($tok -eq '--tabColor' -and ($i+1) -lt $ArgList.Count) { $color = [string]$ArgList[++$i]; continue }
            }

            if ($title -or $color) {
                $cmd = 'wt'
                if ($title) { $cmd += (' --title ' + (Quote-PSLiteral $title)) }
                if ($color) { $cmd += (' --tabColor ' + (Quote-PSLiteral $color)) }
                Send-Text $cmd
                Send-Key $script:_VK.ENTER
                Start-Sleep -Seconds 2
            } else {
                # 既定: Ctrl+Shift+D で新規タブ作成＋固定2秒待機
                Send-KeyCombo @($script:_VK.CTRL, $script:_VK.SHIFT, 0x44) # 'D'
                Start-Sleep -Seconds 2
            }
        }
        '^rename$' {
            $name = ($ArgList | Select-Object -Skip 1) -join ' '
            $cmd = Get-WTCCWTCommand -Key 'rename-tab' -Default 'Rename tab'
            # コマンドパレットを2段階で実行:
            # 1) コマンド名（Rename）を貼り付け → 少し待機 → Enter
            Send-KeyCombo @($script:_VK.CTRL, $script:_VK.SHIFT, $script:_VK.P)
            Send-Text $cmd
            $pre = [Math]::Max(150, 200)
            Start-Sleep -Milliseconds $pre
            Send-Key $script:_VK.ENTER

            # 2) フォーカスが入力欄へ移るのを待機 → 名前を貼り付け → 少し待機 → Enter
            $pre2 = [Math]::Max(200, 200)
            Start-Sleep -Milliseconds $pre2
            # 念のため全選択してから上書き
            Send-KeyCombo @($script:_VK.CTRL, 0x41)  # Ctrl + A
            Send-Text $name
            $post = [Math]::Max(100, 200)
            Start-Sleep -Milliseconds $post
            # 要望: 入力後に Enter を2回送出（間に短い待機を挟む）
            Send-Key $script:_VK.ENTER
            Start-Sleep -Milliseconds 150
            Send-Key $script:_VK.ENTER
            # コンソールに残ったゴミ文字を掃除（インターバルなしでBackspace×20）
            Send-BackspaceBurst -Count 20
        }
        '^color$' {
            $color = ($ArgList | Select-Object -Skip 1) -join ' '
            Invoke-CommandPalette -Query 'Set tab color' -PressEnterAfterQuery -AfterText $color -PressEnterAfterText
        }
    }
    Exit-WTCCFunc -Name 'Invoke-TabCommand'
}

function Invoke-PaneCommand {
    param([string[]]$ArgList)
    Enter-WTCCFunc -Name 'Invoke-PaneCommand' -Params @{ Args = ($ArgList -join ' ') }
    if (-not $ArgList -or $ArgList.Count -lt 1) { return }
    switch -Regex ($ArgList[0]) {
        '^split$' {
            $mode = $ArgList[1]
            if ($mode -notmatch '^(vertical|horizontal)$') {
                Send-KeyCombo @($script:_VK.ALT, $script:_VK.SHIFT, 0x44) # Fallback 'D'
                break
            }
            $scriptPath = Join-Path $PSScriptRoot 'actions\split.ps1'
            $quoted = Quote-PSLiteral $scriptPath
            $cmd = "powershell -NoProfile -ExecutionPolicy Bypass -File $quoted -Mode $mode"
            Send-Text $cmd
            Send-Key $script:_VK.ENTER
        }
        '^resize$' {
            $dir = $ArgList[1]
            $count = [int]($ArgList[2])
            $vk = switch ($dir) {
                'left'  { $script:_VK.LEFT }
                'right' { $script:_VK.RIGHT }
                'up'    { $script:_VK.UP }
                'down'  { $script:_VK.DOWN }
                default { $null }
            }
            if ($vk -ne $null) {
                1..$count | ForEach-Object {
                    # 旧 move の挙動: ALT+SHIFT+矢印でペインサイズ変更
                    Send-KeyCombo @($script:_VK.SHIFT, $script:_VK.ALT, $vk)
                }
            }
        }
        '^move$' {
            $dir = $ArgList[1]
            $count = [int]($ArgList[2])
            $vk = switch ($dir) {
                'left'  { $script:_VK.LEFT }
                'right' { $script:_VK.RIGHT }
                'up'    { $script:_VK.UP }
                'down'  { $script:_VK.DOWN }
                default { $null }
            }
            if ($vk -ne $null) {
                1..$count | ForEach-Object {
                    # 新 move の挙動: ALT+矢印でペイン移動
                    Send-KeyCombo @($script:_VK.ALT, $vk)
                }
            }
        }
        # removed: '^bgcolor$' (deprecated)
        '^bg$' {
            $color = [string]($ArgList | Select-Object -Skip 1)
            if (-not $color) { Write-Warning 'pane bg には #RRGGBB を指定してね'; break }
            $scriptPath = Join-Path $PSScriptRoot 'actions\set-bg.ps1'
            $quoted = Quote-PSLiteral $scriptPath
            $cArg = Quote-PSLiteral $color
            $cmd = "& $quoted -Color $cArg"
            Send-Text $cmd
            Send-Key $script:_VK.ENTER
        }
        '^exec$' {
            $cmdline = ($ArgList | Select-Object -Skip 1) -join ' '
            # ';' 区切りを順次実行
            foreach ($cmd in ($cmdline -split ';')) {
                $text = $cmd.Trim()
                if ($text.Length -gt 0) {
                    Send-Text $text
                    Send-Key $script:_VK.ENTER
                }
            }
        }
    }
    Exit-WTCCFunc -Name 'Invoke-PaneCommand'
}

function Invoke-WindowCommand {
    param([string[]]$ArgList)
    Enter-WTCCFunc -Name 'Invoke-WindowCommand' -Params @{ Args = ($ArgList -join ' ') }
    if (-not (Get-Command Ensure-WTCCWindowType -ErrorAction SilentlyContinue)) {
        function Ensure-WTCCWindowType {
            try { [void][WTCC_Window] } catch {
Add-Type @"
using System;
using System.Runtime.InteropServices;
public static class WTCC_Window {
    [StructLayout(LayoutKind.Sequential)]
    struct RECT { public int Left, Top, Right, Bottom; }
    [DllImport("user32.dll")] static extern IntPtr GetForegroundWindow();
    [DllImport("user32.dll")] static extern bool GetWindowRect(IntPtr hWnd, out RECT lpRect);
    [DllImport("user32.dll", SetLastError=true)] static extern bool MoveWindow(IntPtr hWnd,int X,int Y,int nWidth,int nHeight,bool bRepaint);
    public static bool ResizeActiveWindow(int width, int height) {
        IntPtr h = GetForegroundWindow();
        if (h == IntPtr.Zero) return false;
        RECT r; if (!GetWindowRect(h, out r)) return false;
        return MoveWindow(h, r.Left, r.Top, width, height, true);
    }
}
"@
            }
        }
    }
    Ensure-WTCCWindowType
    if (-not $ArgList -or $ArgList.Count -lt 1) { return }
    switch -Regex ($ArgList[0]) {
        '^size$' {
            $w = [int]$ArgList[1]; $h = [int]$ArgList[2]
            $ok = [WTCC_Window]::ResizeActiveWindow($w, $h)
            Exit-WTCCFunc -Name 'Invoke-WindowCommand' -Result $ok
            return
        }
    }
    Exit-WTCCFunc -Name 'Invoke-WindowCommand'
}

function Resolve-WTCCKeyToken {
    param([Parameter(Mandatory)][string]$Token)
    $t = $Token.Trim().ToLowerInvariant()
    switch ($t) {
        'enter' { return $script:_VK.ENTER }
        'ret' { return $script:_VK.ENTER }
        'return' { return $script:_VK.ENTER }
        'tab' { return $script:_VK.TAB }
        'esc' { return $script:_VK.ESC }
        'escape' { return $script:_VK.ESC }
        'space' { return $script:_VK.SPACE }
        'sp' { return $script:_VK.SPACE }
        'spc' { return $script:_VK.SPACE }
        'spacebar' { return $script:_VK.SPACE }
        default { return $null }
    }
}

function Invoke-KeyCommand {
    param([string[]]$ArgList)
    Enter-WTCCFunc -Name 'Invoke-KeyCommand' -Params @{ Args = ($ArgList -join ' ') }
    if (-not $ArgList -or $ArgList.Count -lt 1) { return }
    $mode = $ArgList[0]
    $rest = if ($ArgList.Count -gt 1) { $ArgList[1..($ArgList.Count-1)] } else { @() }
    if ($mode -ne 'send') { $rest = $ArgList; }
    if (-not $rest -or $rest.Count -eq 0) { return }
    foreach ($tok in $rest) {
        # サフィックス *N の回数指定に対応（例: enter*2）
        $name = $tok; $repeat = 1
        if ($tok -match '^(.*)\*(\d+)$') { $name = $Matches[1]; $repeat = [int]$Matches[2] }
        $vk = Resolve-WTCCKeyToken -Token $name
        if ($null -eq $vk) { Write-Warning ("未知のキー: {0}" -f $tok); continue }
        1..$repeat | ForEach-Object { Send-Key $vk }
    }
    Exit-WTCCFunc -Name 'Invoke-KeyCommand'
}

function Invoke-CommandLine {
    param([string]$Line)
    Enter-WTCCFunc -Name 'Invoke-CommandLine' -Params @{ Line = $Line }
    if (-not $Line) { return }
    $trim = $Line.Trim()
    if ($trim.Length -eq 0) { return }
    if ($trim.StartsWith('#')) { return }

    # トークナイズ（クォート対応）。ただし pane exec は行末生渡し
    $parts = @()
    if ($trim -like 'pane exec *') {
        $parts = @('pane','exec', $trim.Substring(10))
    } else {
        $parts = Split-WTCCTokens -Text $trim
    }

    $major = $parts[0]
    $minorArgs = @()
    if ($parts.Count -gt 1) { $minorArgs = $parts[1..($parts.Count-1)] }

    switch ($major) {
        'tab'    { Invoke-TabCommand    -ArgList $minorArgs }
        'pane'   { Invoke-PaneCommand   -ArgList $minorArgs }
        'window' { Invoke-WindowCommand -ArgList $minorArgs }
        'key'    { Invoke-KeyCommand    -ArgList $minorArgs }
        'key-send' { Invoke-KeyCommand  -ArgList $minorArgs }
        'wait'   {
            # ミリ秒待機: wait <milliseconds>
            $ms = 0
            if ($minorArgs -and $minorArgs.Count -gt 0) {
                try { $ms = [int]$minorArgs[0] } catch { $ms = 0 }
            }
            if ($ms -lt 0) { $ms = 0 }
            if ($ms -gt 0) { Start-Sleep -Milliseconds $ms }
        }
        default  { Write-Warning "未知のコマンド: $Line" }
    }
    Exit-WTCCFunc -Name 'Invoke-CommandLine'
}

Export-ModuleMember -Function *-WTCC*,Send-Key,Send-KeyCombo,Send-Text,Invoke-CommandLine,Invoke-TabCommand,Invoke-PaneCommand,Invoke-WindowCommand,Invoke-KeyCommand,Invoke-CommandPalette,Write-WTCCLog,Enter-WTCCFunc,Exit-WTCCFunc,Test-WTCCDebug
