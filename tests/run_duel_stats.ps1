# Headless duel statistics. (ASCII only: Windows PowerShell 5.1 reads BOM-less files as ANSI.)
#
#   powershell -ExecutionPolicy Bypass -File tests/run_duel_stats.ps1
#   powershell -ExecutionPolicy Bypass -File tests/run_duel_stats.ps1 -Runs 50 -Delay 0.3 -Counter mid,same,thrust -Miss 0.1
#   powershell -ExecutionPolicy Bypass -File tests/run_duel_stats.ps1 -Opponent res://data/opponents/opponent_01.tres
#   powershell -ExecutionPolicy Bypass -File tests/run_duel_stats.ps1 -Runs 30 -Opening off,1,2,3
#
# Runs tests/duel_stats.gd: a bot plays whole duels and prints one "stat," line per setting
# (length, endings, hits by reason, how openings ended) and one "routes," line (pattern routes seen).
# -Delay: seconds the bot waits before countering. -Miss: chance to guard the wrong height.
# -Opening: opening chance settings (base = as the data says, off = always opens, 1/2/3 = that day). Default base.
# -Bonus: adds to the chance of the day settings 1/2/3 only (the upgrade), e.g. -Opening 3 -Bonus 0.15. Default 0.
# -Counter: where the counter is aimed (same = the guarded cell, mid = same side mid row, thrust = centre mid).
# Without -Opponent it plays every opponent in data/opponents/trial, 9-cell and flat.
# Judges the run: exit code 0, one "DUEL STATS OK <n>" line, no ERROR lines. The numbers are not judged.
param(
	[switch]$SkipImport,
	[string]$Godot,
	[int]$Runs = 20,
	[double]$Delay = 0.25,
	[double]$Miss = 0.0,
	[string]$Counter = 'mid',
	[string[]]$Opponent = @(),
	[string]$Opening = 'base',
	[double]$Bonus = 0.0
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

$inv = [System.Globalization.CultureInfo]::InvariantCulture
$userArgs = "--runs=$Runs --delay=$($Delay.ToString($inv)) --miss=$($Miss.ToString($inv)) --counter=$Counter --opening=$Opening --bonus=$($Bonus.ToString($inv))"
foreach ($path in $Opponent) { $userArgs += " --opponent=$path" }
$out = cmd /c "`"$Godot`" --headless --path `"$project`" --script res://tests/duel_stats.gd -- $userArgs 2>&1"
$runExit = $LASTEXITCODE
$out | Where-Object { $_ -match '^(stat|routes),|^DUEL STATS|ERROR|WARNING' } | ForEach-Object { Write-Output $_ }

$errors = @($out | Where-Object { $_ -match $errorPattern })
$ok = @($out | Where-Object { $_ -match '^DUEL STATS OK \d+$' })

$reasons = @()
if ($runExit -ne 0) { $reasons += "exit code $runExit" }
if ($ok.Count -ne 1) { $reasons += 'no "DUEL STATS OK" line' }
if ($errors.Count -gt 0) { $reasons += "error lines $($errors.Count)" }

Write-Output ''
if ($reasons.Count -eq 0) {
	Write-Output "RESULT: OK ($($ok[0]), error lines 0)"
	exit 0
}
Write-Output "RESULT: FAIL ($($reasons -join ', '))"
exit 1
