param(
  [Parameter(Mandatory=$true)][ValidateSet('vertical','horizontal')]
  [string]$Mode
)

Add-Type -AssemblyName System.Windows.Forms

switch ($Mode) {
  'vertical'   { [System.Windows.Forms.SendKeys]::SendWait('%+{;}') }
  'horizontal' { [System.Windows.Forms.SendKeys]::SendWait('%+{=}') }
}

