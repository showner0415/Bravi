# Whole-day smoke wrapper. (ASCII only: Windows PowerShell 5.1 reads BOM-less files as ANSI.)
#
#   powershell -ExecutionPolicy Bypass -File tests/run_smoke.ps1
#
# Runs tests/day_smoke.tscn as a scene (autoloads are live) and drives one full day through the
# real scene changes: title -> (counter -> duel -> settlement) x3 -> closing -> day 2 counter.
# 1. Refreshes the class cache (a stale cache makes scripts with new class_names fail to parse).
# 2. Runs the smoke scene headless.
# 3. Judges the run: exit code 0, a "DAY SMOKE OK" line, and no ERROR lines. All three are required.
#
# Godot path: -Godot argument, else the GODOT environment variable, else the candidates in
# tests/godot_path.ps1.
param(
	[string]$Godot
)

. "$PSScriptRoot\godot_path.ps1"
$Godot = Find-Godot $Godot
if (-not (Test-Path -LiteralPath $Godot -PathType Leaf)) {
	Write-Output "RESULT: FAIL (Godot not found: $Godot  -- pass -Godot <path> or set GODOT)"
	exit 1
}

$project = Split-Path -Parent $PSScriptRoot
# Godot prints UTF-8.
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$errorPattern = '^\s*(USER |)(SCRIPT |)ERROR:'

# cmd merges stderr into stdout (ERROR lines go to stderr).
$import = cmd /c "`"$Godot`" --headless --path `"$project`" --import 2>&1"
$importExit = $LASTEXITCODE
$importErrors = @($import | Where-Object { $_ -match $errorPattern })
if ($importExit -ne 0 -or $importErrors.Count -gt 0) {
	$importErrors | ForEach-Object { Write-Output $_ }
	Write-Output "RESULT: FAIL (import step: exit code $importExit, error lines $($importErrors.Count))"
	exit 1
}

$out = cmd /c "`"$Godot`" --headless --path `"$project`" res://tests/day_smoke.tscn --quit-after 6000 2>&1"
$smokeExit = $LASTEXITCODE
$out | ForEach-Object { Write-Output $_ }

$errors = @($out | Where-Object { $_ -match $errorPattern })
$warnings = @($out | Where-Object { $_ -match '^\s*WARNING:' })
$ok = @($out | Where-Object { $_ -match '^DAY SMOKE OK' })

$reasons = @()
if ($smokeExit -ne 0) { $reasons += "exit code $smokeExit" }
if ($ok.Count -ne 1) { $reasons += 'no "DAY SMOKE OK" line' }
if ($errors.Count -gt 0) { $reasons += "error lines $($errors.Count)" }

Write-Output ''
if ($reasons.Count -eq 0) {
	Write-Output "RESULT: OK (DAY SMOKE OK, error lines 0, warning lines $($warnings.Count))"
	exit 0
}
Write-Output "RESULT: FAIL ($($reasons -join ', '))"
exit 1
