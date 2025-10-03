<#
  TabActions.psm1
  - Windows Terminal のタブ操作ヘルパー
  - Tab-Create は引数文字列をそのまま wt に渡す（ノーパース）
#>

# helpers.psm1 依存の自動Import
if (-not (Get-Command Invoke-PaneCommand -ErrorAction SilentlyContinue)) {
  try {
    $helpers = Join-Path (Split-Path $PSScriptRoot -Parent) 'helpers.psm1'
    if (Test-Path -LiteralPath $helpers) { Import-Module -Force -Scope Local -Name $helpers }
  } catch { Write-Warning ("helpers.psm1 のImport失敗: {0}" -f $_.Exception.Message) }
}

function Tab-Create {
  [CmdletBinding()] param(
    [string]$Args
  )
  $cmd = if ([string]::IsNullOrWhiteSpace($Args)) { 'wt' } else { 'wt ' + $Args }
  Invoke-PaneCommand -ArgList @('exec', $cmd)
}

Export-ModuleMember -Function Tab-*

