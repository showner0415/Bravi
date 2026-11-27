# Event-line golden (plan 044, decision 679). (ASCII only: Windows PowerShell 5.1 reads BOM-less files as ANSI.)
#
#   powershell -ExecutionPolicy Bypass -File tests/run_event_digest.ps1          # compare with tests/golden/event_digest.txt
#   powershell -ExecutionPolicy Bypass -File tests/run_event_digest.ps1 -Write   # write the golden (only on a commit before the code changes)
#
# Runs tests/event_digest.gd: 6 opponents x tier {1, last} x bot {first_blood, parry} = 24 duels (7 seeds x 60 s each),
# one "digest," line per duel. Judges the run: exit code 0, one "EVENT DIGEST OK" (or "WRITTEN 24") line, no ERROR lines.
param(
	[switch]$SkipImport,
	[switch]$Write,
	[string]$Godot
)

. "$PSScriptRoot\godot_path.ps1"
$Godot = Find-Godot $Godot
if (-not (Test-Path -LiteralPath $Godot -PathType Leaf)) {
	Write-Output "RESULT: FAIL (Godot not found: $Godot  -- pass -Godot <path> or set GODOT)"
	exit 1
}

$project = Split-Path -Parent $PSScriptRoot
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$errorPattern = '^\s*(USER |)(SCRIPT |)ERROR:'

if (-not $SkipImport) {
	$import = cmd /c "`"$Godot`" --headless --path `"$project`" --import 2>&1"
	$importExit = $LASTEXITCODE
	$importErrors = @($import | Where-Object { $_ -match $errorPattern })
	if ($importExit -ne 0 -or $importErrors.Count -gt 0) {
		$importErrors | ForEach-Object { Write-Output $_ }
		Write-Output "RESULT: FAIL (import step: exit code $importExit, error lines $($importErrors.Count))"
		exit 1
	}
}

$userArgs = ''
if ($Write) { $userArgs = ' --write' }
$out = cmd /c "`"$Godot`" --headless --path `"$project`" --script res://tests/event_digest.gd --$userArgs 2>&1"
$runExit = $LASTEXITCODE
$out | Where-Object { $_ -match '^digest,|^\s*(INFO|DIFF)|^EVENT DIGEST|ERROR|WARNING' } | ForEach-Object { Write-Output $_ }

$errors = @($out | Where-Object { $_ -match $errorPattern })
$ok = @($out | Where-Object { $_ -match '^EVENT DIGEST (OK \d+ skipped \d+|WRITTEN \d+)$' })

$reasons = @()
if ($runExit -ne 0) { $reasons += "exit code $runExit" }
if ($ok.Count -ne 1) { $reasons += 'no "EVENT DIGEST OK/WRITTEN" line' }
if ($errors.Count -gt 0) { $reasons += "error lines $($errors.Count)" }

Write-Output ''
if ($reasons.Count -eq 0) {
	Write-Output "RESULT: OK ($($ok[0]), error lines 0)"
	exit 0
}
Write-Output "RESULT: FAIL ($($reasons -join ', '))"
exit 1
