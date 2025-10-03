<#
  PaneActions.psm1
  - WTCCのbuilder用ヘルパー関数群（読みやすさ重視の薄いラッパー）
  - 前提: 同プロセスで WTCC の helpers.psm1 が読み込まれており、Invoke-PaneCommand 等が使用可能
#>

function Get-PaneActionScriptPath {
  param([Parameter(Mandatory)][ValidateSet('split','set-bg','resize')] [string]$Name)
  return (Join-Path $PSScriptRoot ("{0}.ps1" -f $Name))
}

function Pane-Split {
  [CmdletBinding()] param(
    [Parameter(Mandatory)][ValidateSet('vertical','horizontal')] [string]$Mode
  )
  $path = Get-PaneActionScriptPath -Name 'split'
  $cmd  = "powershell -NoProfile -ExecutionPolicy Bypass -File '{0}' -Mode '{1}'" -f $path, $Mode
  Invoke-PaneCommand -ArgList @('exec', $cmd)
}

function Pane-SetBg {
  [CmdletBinding()] param(
    [Parameter(Mandatory)][string]$Color
  )
  $path = Get-PaneActionScriptPath -Name 'set-bg'
  $cmd  = "powershell -NoProfile -ExecutionPolicy Bypass -File '{0}' -Color '{1}'" -f $path, $Color
  Invoke-PaneCommand -ArgList @('exec', $cmd)
}

function Pane-Resize {
  [CmdletBinding()] param(
    [Parameter(Mandatory)][ValidateSet('left','right','up','down')] [string]$Direction,
    [int]$Count = 1
  )
  $path = Get-PaneActionScriptPath -Name 'resize'
  $cmd  = "powershell -NoProfile -ExecutionPolicy Bypass -File '{0}' -Direction '{1}' -Count {2}" -f $path, $Direction, $Count
  Invoke-PaneCommand -ArgList @('exec', $cmd)
}

function Pane-Exec {
  [CmdletBinding()] param(
    [Parameter(Mandatory)][string]$Command
  )
  Invoke-PaneCommand -ArgList @('exec', $Command)
}

function Pane-ExecMany {
  [CmdletBinding()] param(
    [Parameter(Mandatory)][string[]]$Commands
  )
  foreach ($c in $Commands) {
    if ([string]::IsNullOrWhiteSpace($c)) { continue }
    Invoke-PaneCommand -ArgList @('exec', $c)
  }
}

Export-ModuleMember -Function Pane-*

