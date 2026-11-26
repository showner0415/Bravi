# Headless "how late can I still press" table per aimed part. (ASCII only: Windows PowerShell 5.1 reads BOM-less files as ANSI.)
#
#   powershell -ExecutionPolicy Bypass -File tests/run_part_reach.ps1
#   powershell -ExecutionPolicy Bypass -File tests/run_part_reach.ps1 -Opponent res://data/opponents/opponent_01.tres -Distance engage,close
#   powershell -ExecutionPolicy Bypass -File tests/run_part_reach.ps1 -All > reach.log
#
# Runs tests/part_reach.gd: for each attack of the opponent (boiled down to that attack alone, opening chance 1.0, no bind),
# the bot blocks or parries it, then a fresh duel presses the attack d seconds after the strike (d = 0, 1/120, 2/120 ...)
# and the latest d that still touches is printed in one "reach," line per aimed cell.
# Default: opponent_01, attack "Left cut" (the Korean default lives in the script), distance engage, -Effects off,on = 18 old + 18 new lines.
# -Effects: off (old rule), on (data/part_effects.tres), or both comma-separated (the default).
# -Attack: attack name, spaces written as "_" (e.g. -Attack Left_cut). -Distance: engage,close. -All: every opponent, attack, distance.
# Judges the run: exit code 0, one "PART REACH OK <n>" line, no MISMATCH lines, no ERROR lines.
param(
	[switch]$SkipImport,
	[string]$Godot,
	[string[]]$Opponent = @(),
	[string]$Attack = '',
	[string]$Distance = '',
	[string]$Effects = '',
	[switch]$All
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
if ($All) { $userArgs += ' --all' }
if ($Attack) { $userArgs += " --attack=$($Attack -replace ' ', '_')" }
if ($Distance) { $userArgs += " --distance=$Distance" }
if ($Effects) { $userArgs += " --effects=$Effects" }
foreach ($path in $Opponent) { $userArgs += " --opponent=$path" }
$out = cmd /c "`"$Godot`" --headless --path `"$project`" --script res://tests/part_reach.gd -- $userArgs 2>&1"
$runExit = $LASTEXITCODE
$out | Where-Object { $_ -match '^reach,|^PART REACH|ERROR|WARNING' } | ForEach-Object { Write-Output $_ }

$errors = @($out | Where-Object { $_ -match $errorPattern })
$ok = @($out | Where-Object { $_ -match '^PART REACH OK \d+$' })
$mismatch = @($out | Where-Object { $_ -match '^reach,.*MISMATCH' })

$reasons = @()
if ($runExit -ne 0) { $reasons += "exit code $runExit" }
if ($ok.Count -ne 1) { $reasons += 'no "PART REACH OK" line' }
if ($mismatch.Count -gt 0) { $reasons += "MISMATCH lines $($mismatch.Count)" }
if ($errors.Count -gt 0) { $reasons += "error lines $($errors.Count)" }

Write-Output ''
if ($reasons.Count -eq 0) {
	Write-Output "RESULT: $($ok[0])"
	exit 0
}
Write-Output "RESULT: FAIL ($($reasons -join ', '))"
exit 1
