param(
  [Parameter(Mandatory=$true)][string]$Color
)

# 背景色（OSC 11）を発行
Write-Host "`e]11;$Color`a"

