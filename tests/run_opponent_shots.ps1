# Opponent art shots (plan 029, task 8). (ASCII only: Windows PowerShell 5.1 reads BOM-less files as ANSI.)
#
#   powershell -ExecutionPolicy Bypass -File tests/run_opponent_shots.ps1 -Shots "$env:TEMP\bravi-029-shots"
#   powershell -ExecutionPolicy Bypass -File tests/run_opponent_shots.ps1            (headless, saves nothing)
#
# Runs tests/opponent_shots.tscn: the opponent view alone, one PNG per state (41).
# With -Shots it opens a window (the shots need a renderer) and also writes the measuring points
# (lines starting "pt,") to <Shots>\pts.txt.
# Judges the run: exit code 0, the last "OPPONENT SHOTS OK <n>" line, and no ERROR / SHADER ERROR lines.
#
# Godot path: -Godot argument, else the GODOT environment variable, else the candidates in
# tests/godot_path.ps1.
param(
	[string]$Godot,
	[string]$Shots
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
$errorPattern = '^\s*(USER |)(SCRIPT |SHADER |)ERROR'

# cmd merges stderr into stdout (ERROR lines go to stderr).
$import = cmd /c "`"$Godot`" --headless --path `"$project`" --import 2>&1"
$importExit = $LASTEXITCODE
$importErrors = @($import | Where-Object { $_ -match $errorPattern })
if ($importExit -ne 0 -or $importErrors.Count -gt 0) {
	$importErrors | ForEach-Object { Write-Output $_ }
	Write-Output "RESULT: FAIL (import step: exit code $importExit, error lines $($importErrors.Count))"
	exit 1
}

if ($Shots) {
	New-Item -ItemType Directory -Force -Path $Shots | Out-Null
	$out = cmd /c "`"$Godot`" --path `"$project`" res://tests/opponent_shots.tscn --quit-after 6000 -- `"--shots=$Shots`" 2>&1"
} else {
	$out = cmd /c "`"$Godot`" --headless --path `"$project`" res://tests/opponent_shots.tscn --quit-after 6000 2>&1"
}
$runExit = $LASTEXITCODE
$out | ForEach-Object { Write-Output $_ }
if ($Shots) {
	$out | Where-Object { $_ -match '^pt,' } | Set-Content -Encoding ASCII -Path (Join-Path $Shots 'pts.txt')
}

$errors = @($out | Where-Object { $_ -match $errorPattern })
$warnings = @($out | Where-Object { $_ -match '^\s*WARNING:' })
$ok = @($out | Where-Object { $_ -match '^OPPONENT SHOTS OK \d+' })

$reasons = @()
if ($runExit -ne 0) { $reasons += "exit code $runExit" }
if ($ok.Count -ne 1) { $reasons += 'no "OPPONENT SHOTS OK" line' }
if ($errors.Count -gt 0) { $reasons += "error lines $($errors.Count)" }

Write-Output ''
if ($reasons.Count -eq 0) {
	Write-Output "RESULT: OK ($($ok[0]), error lines 0, warning lines $($warnings.Count))"
	exit 0
}
Write-Output "RESULT: FAIL ($($reasons -join ', '))"
exit 1
