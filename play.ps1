# Starts the game. (ASCII only: Windows PowerShell 5.1 reads BOM-less files as ANSI.)
#
#   powershell -ExecutionPolicy Bypass -File play.ps1
#   powershell -ExecutionPolicy Bypass -File play.ps1 --headless --quit-after 300
#
# 1. Refreshes the class cache (.godot/ is not in git). After a branch switch a stale cache makes
#    scripts with new class_names fail to parse, and the game opens on a dead title screen.
# 2. Runs the main scene. Every argument other than -Godot is passed on to Godot as-is.
#    Waits until the game window closes and exits with Godot's exit code.
#
# Godot path: -Godot argument, else the GODOT environment variable, else the candidates in
# tests/godot_path.ps1.
# PositionalBinding is off so that "--headless" is not taken as the -Godot value.
[CmdletBinding(PositionalBinding = $false)]
param(
	[string]$Godot,
	[Parameter(ValueFromRemainingArguments = $true)]
	[string[]]$GodotArgs
)

. "$PSScriptRoot\tests\godot_path.ps1"
$Godot = Find-Godot $Godot
if (-not (Test-Path -LiteralPath $Godot -PathType Leaf)) {
	Write-Output "RESULT: FAIL (Godot not found: $Godot  -- pass -Godot <path> or set GODOT)"
	exit 1
}

$project = $PSScriptRoot
# Godot prints UTF-8.
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$errorPattern = '^\s*(USER |)(SCRIPT |)ERROR:'

# cmd merges stderr into stdout (PowerShell 5.1 would wrap stderr lines as error records).
$import = cmd /c "`"$Godot`" --headless --path `"$project`" --import 2>&1"
$importExit = $LASTEXITCODE
$importErrors = @($import | Where-Object { $_ -match $errorPattern })
if ($importExit -ne 0 -or $importErrors.Count -gt 0) {
	$importErrors | ForEach-Object { Write-Output $_ }
	Write-Output "RESULT: FAIL (import step: exit code $importExit, error lines $($importErrors.Count))"
	exit 1
}

$extra = ''
if ($GodotArgs) {
	$extra = ($GodotArgs | ForEach-Object { if ($_ -match '\s') { "`"$_`"" } else { $_ } }) -join ' '
}
# The console executable blocks until the game window closes.
cmd /c "`"$Godot`" --path `"$project`" $extra 2>&1" | ForEach-Object { Write-Output $_ }
exit $LASTEXITCODE
