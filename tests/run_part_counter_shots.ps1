# Part counter shots (plan R02, task 7). (ASCII only: Windows PowerShell 5.1 reads BOM-less files as ANSI.)
#
#   powershell -ExecutionPolicy Bypass -File tests/run_part_counter_shots.ps1                     (headless: counter and overlap lines only)
#   powershell -ExecutionPolicy Bypass -File tests/run_part_counter_shots.ps1 -Shots "$env:TEMP\bravi-counter"
#
# Runs tests/part_counter_shots.tscn: five scenes (body, arm, late-arm, late-body, too-late) x two shots (before the press, after the verdict).
# Prints "counter," lines (preview and outcome per scene; a FAIL tail when they differ from the plan's table, and one flicker line)
# and "overlap," lines (the aim tag or effect text over a HUD panel, label or the screen edge).
# Judges the run: exit code 0, one "PART COUNTER SHOTS OK <n>" line, no ERROR lines, no counter line ending in FAIL. Overlaps are reported, not judged.
param(
	[switch]$SkipImport,
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
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$errorPattern = '^\s*(USER |)(SCRIPT |SHADER |)ERROR'

if (-not $SkipImport) {
	cmd /c "`"$Godot`" --headless --path `"$project`" --import 2>&1" | Out-Null
	$import = cmd /c "`"$Godot`" --headless --path `"$project`" --import 2>&1"
	$importExit = $LASTEXITCODE
	$importErrors = @($import | Where-Object { $_ -match $errorPattern })
	if ($importExit -ne 0 -or $importErrors.Count -gt 0) {
		$importErrors | ForEach-Object { Write-Output $_ }
		Write-Output "RESULT: FAIL (import step: exit code $importExit, error lines $($importErrors.Count))"
		exit 1
	}
}

if ($Shots) {
	New-Item -ItemType Directory -Force -Path $Shots | Out-Null
	$out = cmd /c "`"$Godot`" --path `"$project`" res://tests/part_counter_shots.tscn --quit-after 20000 -- `"--shots=$Shots`" 2>&1"
} else {
	$out = cmd /c "`"$Godot`" --headless --path `"$project`" res://tests/part_counter_shots.tscn --quit-after 20000 2>&1"
}
$runExit = $LASTEXITCODE
$out | ForEach-Object { Write-Output $_ }

$errors = @($out | Where-Object { $_ -match $errorPattern })
$ok = @($out | Where-Object { $_ -match '^PART COUNTER SHOTS OK \d+$' })
$counters = @($out | Where-Object { $_ -match '^counter,' })
$failed = @($counters | Where-Object { $_ -match 'FAIL' })
$overlaps = @($out | Where-Object { $_ -match '^overlap,' })

$reasons = @()
if ($runExit -ne 0) { $reasons += "exit code $runExit" }
if ($ok.Count -ne 1) { $reasons += 'no "PART COUNTER SHOTS OK" line' }
if ($errors.Count -gt 0) { $reasons += "error lines $($errors.Count)" }
if ($failed.Count -gt 0) { $reasons += "counter FAIL lines $($failed.Count)" }

Write-Output ''
if ($reasons.Count -eq 0) {
	Write-Output "RESULT: OK ($($ok[0]), counter lines $($counters.Count), overlap lines $($overlaps.Count), error lines 0)"
	exit 0
}
Write-Output "RESULT: FAIL ($($reasons -join ', '))"
exit 1
