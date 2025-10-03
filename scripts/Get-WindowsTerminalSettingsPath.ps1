function Get-WindowsTerminalSettingsPath {
    # 候補パス一覧
    $candidates = @(
        "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json", # Store版
        "$env:LOCALAPPDATA\Microsoft\Windows Terminal\settings.json"                                    # winget/Scoop/GitHub版
    )

    foreach ($path in $candidates) {
        if (Test-Path $path) {
            return (Resolve-Path $path).Path
        }
    }

    return $null
}

