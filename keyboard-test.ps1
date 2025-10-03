# 最小限のキーボードエミュレーションテスト (keybd_event)
# 事前に Notepad を起動してアクティブにしておいてください

Add-Type @"
using System;
using System.Runtime.InteropServices;

public static class SimpleKeyboard2 {
    [DllImport("user32.dll", SetLastError = true)]
    public static extern void keybd_event(byte bVk, byte bScan, uint dwFlags, UIntPtr dwExtraInfo);

    private const int KEYEVENTF_KEYDOWN = 0x0000;
    private const int KEYEVENTF_KEYUP   = 0x0002;

    public static void KeyDown(byte vk) {
        keybd_event(vk, 0, KEYEVENTF_KEYDOWN, UIntPtr.Zero);
    }

    public static void KeyUp(byte vk) {
        keybd_event(vk, 0, KEYEVENTF_KEYUP, UIntPtr.Zero);
    }

    public static void KeyPress(byte vk, int delayMs) {
        KeyDown(vk);
        System.Threading.Thread.Sleep(delayMs);
        KeyUp(vk);
    }
}
"@

# ユーザーにキー入力を促す
Write-Host "Notepad をアクティブにしてください。準備ができたら Enter キーを押してください..."
[void][System.Console]::ReadKey($true)

Write-Host "3秒後に Notepad へ入力テストを送信します..."
Start-Sleep -Seconds 3

# A, B, C を順番に入力
[SimpleKeyboard2]::KeyPress(0x41, 100)  # A
[SimpleKeyboard2]::KeyPress(0x42, 100)  # B
[SimpleKeyboard2]::KeyPress(0x43, 100)  # C

Write-Host "テスト完了: Notepad に「ABC」と入力されていれば成功"
