# Headless duel statistics. (ASCII only: Windows PowerShell 5.1 reads BOM-less files as ANSI.)
#
#   powershell -ExecutionPolicy Bypass -File tests/run_duel_stats.ps1
#   powershell -ExecutionPolicy Bypass -File tests/run_duel_stats.ps1 -Runs 50 -Delay 0.3 -Counter mid,same,thrust -Miss 0.1
#   powershell -ExecutionPolicy Bypass -File tests/run_duel_stats.ps1 -Opponent res://data/opponents/opponent_01.tres
#   powershell -ExecutionPolicy Bypass -File tests/run_duel_stats.ps1 -Runs 30 -Opening off,1,2,3
#   powershell -ExecutionPolicy Bypass -File tests/run_duel_stats.ps1 -Opponent res://data/opponents/opponent_01.tres -Opening 1 -Effects off,on -Counter thrust,arm,low -Nine
#
# Runs tests/duel_stats.gd: a bot plays whole duels and prints one "stat," line per setting
# (length, endings, hits by reason, how openings ended) and one "routes," line (pattern routes seen).
# -Delay: seconds the bot waits before countering. -Miss: chance to guard the wrong height.
# -Opening: opening chance settings (base = as the data says, off = always opens, 1/2/3 = that day). Default base.
# -Bonus: adds to the chance of the day settings 1/2/3 only (the upgrade), e.g. -Opening 3 -Bonus 0.15. Default 0.
# -Dive: block (default) or retreat: how the bot meets a dive attack (retreat = step back, then strike the opening).
# -Counter: where the counter is aimed (same = the guarded cell, mid = same side mid row, thrust = centre mid, arm = sword-arm mid row, low = centre low row).
# -Effects: off (default, the old rule) and/or on (data/part_effects.tres worn by the opponent copy). The stat line ends with ",<old|new>,effects{...}" (plan R02).
# -Nine: only the 9-cell rows (skips the "flat" rows of opponents that have heights).
# -Tier: sword-style tiers as the screen counts them (1 = first), a list or "last" (each opponent's last tier), e.g. -Tier 1,3,last. The opponent name in the line becomes e.g. opponent_01-t3. Default none (lines as before).
# -Guard: hold (default, the bot holds the guard) or parry (the beat bot: tries to parry every strike). -Jitter: the beat bot press error as a share of the wait, e.g. -Guard parry -Jitter 0.15 (error = jitter * wait * random -1..1 seconds). Given, the stat line gets ",guard=..,jitter=.." after miss; not given, lines are as before.
# -Commission: a commission .tres (res:// path); the bot plays by its conditions, hat and opponent fit (without -Opponent, the commission opponent only). -Finisher off: the bot does not strike a staggered opponent (plan 043); -Finisher low: it finishes a staggered opponent in the leg row (plan 046); -Finisher top: in the top row on the sword side (the hat, or the sword hand; plan 047). Given, the stat line gets ",commission=..,finisher=.." after miss, and each setting adds a "score," line (full / partial / zero scores, mean, topples per duel) and, for a target-part commission, a "parts," line (my grazes and hits per part per duel, duels with a graze off the target); not given, lines are as before.
# -Bite: the bite bot (plan 044): chance to guard the cell of a feint (a hollow dotted ring) and be fooled, e.g. -Bite 0.3 (0 = never, 1 = always). Given, the stat line gets ",bite=.." after miss; opponents with feints also print a "feint," line (feints, bitten, lost openings per duel; share of feint patterns that fooled the bot). Not given, lines are as before.
# -Chase: the chase bot (plan 045): chance to follow an opponent that struck and stepped back (release the guard, step in, strike inside the opening), per withdraw opening, e.g. -Chase 0 (never) -Chase 0.5. Default: always follows. Given, the stat line gets ",chase=.." after miss; opponents that withdraw also print a "withdraw," line (withdraws, open withdraws, reached by the chase per duel; reach share). Not given, lines are as before.
# -Patient: the patient bot (plan 048): it does not counter until the commission meter (hold: blocks counted) is full; the stat line gets ",patient". -Finisher arm / head: the bot finishes on the sword-arm mid row / centre high row. A hold commission also prints one "hold," line (runs, runs that reached the block count, mean time reached, early touches per run).
# -Aim: center (default, the counter aim as -Counter says) or last (the guarded strike cell as it was: plan 053 the bot that counters the last cell). -Spike: chance the bot does not read the spike cover on a covered opening, e.g. -Spike 1 (0 = always reads). Given, the stat line gets ",aim=last" and ",spike=.."; opponents with a spike cover also print a "cover," line (covers, caught, reached aside per duel; reached share, caught share).
# The stat line ends with ",<label> <sum>" after the effects{...}: the label is the Korean word for "hit total" and the sum is total hits taken per duel (two decimals).
# Without -Opponent it plays every opponent in data/opponents, 9-cell and flat.
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
	[double]$Bonus = 0.0,
	[string]$Dive = 'block',
	[string]$Effects = 'off',
	[switch]$Nine,
	[string]$Tier = '',
	[string]$Guard = '',
	[string]$Jitter = '',
	[string]$Commission = '',
	[string]$Finisher = '',
	[string]$Bite = '',
	[string]$Chase = '',
	[switch]$Patient,
	[string]$Aim = '',
	[string]$Spike = ''
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
$userArgs = "--runs=$Runs --delay=$($Delay.ToString($inv)) --miss=$($Miss.ToString($inv)) --counter=$Counter --opening=$Opening --bonus=$($Bonus.ToString($inv)) --dive=$Dive --effects=$Effects"
if ($Nine) { $userArgs += " --nine" }
if ($Tier) { $userArgs += " --tier=$Tier" }
if ($Guard) { $userArgs += " --guard=$Guard" }
if ($Jitter) { $userArgs += " --jitter=$Jitter" }
if ($Commission) { $userArgs += " --commission=$Commission" }
if ($Finisher) { $userArgs += " --finisher=$Finisher" }
if ($Bite) { $userArgs += " --bite=$Bite" }
if ($Chase) { $userArgs += " --chase=$Chase" }
if ($Patient) { $userArgs += " --patient" }
if ($Aim) { $userArgs += " --aim=$Aim" }
if ($Spike) { $userArgs += " --spike=$Spike" }
foreach ($path in $Opponent) { $userArgs += " --opponent=$path" }
$out = cmd /c "`"$Godot`" --headless --path `"$project`" --script res://tests/duel_stats.gd -- $userArgs 2>&1"
$runExit = $LASTEXITCODE
$out | Where-Object { $_ -match '^(stat|routes|score|feint|withdraw|parts|hold|cover),|^DUEL STATS|ERROR|WARNING' } | ForEach-Object { Write-Output $_ }

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
