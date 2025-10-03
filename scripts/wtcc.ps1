param(
    [string]$ScriptPath = "./script.txt",
    [int]$Interval = 500
)

$entry = Join-Path (Split-Path -Path $MyInvocation.MyCommand.Path -Parent) '..\wtcc.ps1'
& $entry -ScriptPath $ScriptPath -Interval $Interval
