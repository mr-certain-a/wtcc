param(
  [Parameter(Mandatory=$true)][ValidateSet('left','right','up','down')]
  [string]$Direction,
  [int]$Count = 1
)

Add-Type -AssemblyName System.Windows.Forms

$token = switch ($Direction) {
  'left'  { '{LEFT}' }
  'right' { '{RIGHT}' }
  'up'    { '{UP}' }
  'down'  { '{DOWN}' }
}

if (-not $Count -or $Count -lt 1) { $Count = 1 }
for ($i=0; $i -lt $Count; $i++) {
  # Move: Alt + Arrow（フォーカス移動/ペイン移動の新仕様に対応）
  [System.Windows.Forms.SendKeys]::SendWait('%' + $token)
}

