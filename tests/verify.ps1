# One-shot verification with a short report. (ASCII only: Windows PowerShell 5.1 reads BOM-less files as ANSI.)
#
#   powershell -ExecutionPolicy Bypass -File tests/verify.ps1
#   powershell -ExecutionPolicy Bypass -File tests/verify.ps1 -Only tests,smoke
#   powershell -ExecutionPolicy Bypass -File tests/verify.ps1 -Shots "$env:TEMP\bravi-shots" -Stats
#
# Imports once, then runs the steps with -SkipImport: tests, smoke, opponent (shots), ui (shots), pattern (shots).
# -Stats adds the headless duel statistics (tests/run_duel_stats.ps1 with its defaults; run that script for other settings). It also adds the part-reach table (tests/run_part_reach.ps1 defaults; its "reach," lines are printed).
# -Shots <dir>: the three shot steps open a window and save PNGs under <dir>\opponent, <dir>\ui, <dir>\pattern.
# Prints one line per step, and only for a failed step its ERROR / FAIL lines. Full output goes to <log dir>\<step>.log.
# -Stats also adds tierwrong and tierclean (each opponent's last sword-style tier, -Opening 3 -Nine; -Miss 0.1 for tierwrong): their "stat," lines are printed.
# -Stats also adds spar, sparwrong, sparparry (plan 043 decision 662: run_duel_stats.ps1 -Commission res://data/commissions/spar.tres -Opening 3 -Nine -Finisher off -Runs 60; sparwrong adds -Miss 0.1, sparparry adds -Guard parry -Jitter 0). These three steps print "stat," and "score," lines.
# -Stats also adds court, courtwrong, courtnaive, noble, noblewrong (plan 046 decision 741; the five bands are in the plan). They print "stat,", "score," and "parts," lines.
# -Stats also adds pairhat, pairhatwrong, pairspar, pairsparclean, afterhand (plan 047 decision 760; the bands are in the plan). They print "stat,", "score," and "parts," lines.
# -Stats also adds hold, holdwrong, holdrash, sleeve, dunhead (plan 048 decision 778; the bands are in the plan). They print "stat,", "score,", "hold," and "parts," lines.
# The counter step (tests/part_counter_shots.gd) prints its "counter," and "overlap," lines; the partstats step (run_duel_stats.ps1 with $extra args) prints its "stat," lines.
# Also prints the pattern step's "overlap," lines and the stats step's "stat," lines: they are what a reader needs.
# Sets BRAVI_SAVE_PATH to the playtest save when it is not set, so no run touches the player's save.
# Likewise BRAVI_SETTINGS_PATH to the playtest settings file, so no run touches the player's settings.
# Exits 0 when every step passed, 1 otherwise. Last line: "VERIFY: OK" or "VERIFY: FAIL (<steps>)".
param(
	[string]$Godot,
	[string]$Only = '',
	[string]$Shots = '',
	[switch]$Stats,
	[string]$LogDir = ''
)

. "$PSScriptRoot\godot_path.ps1"
$Godot = Find-Godot $Godot
if (-not (Test-Path -LiteralPath $Godot -PathType Leaf)) {
	Write-Output "VERIFY: FAIL (Godot not found: $Godot  -- pass -Godot <path> or set GODOT)"
	exit 1
}
if (-not $env:BRAVI_SAVE_PATH) { $env:BRAVI_SAVE_PATH = 'user://bravi_playtest_save.json' }
if (-not $env:BRAVI_SETTINGS_PATH) { $env:BRAVI_SETTINGS_PATH = 'user://bravi_playtest_settings.json' }

$project = Split-Path -Parent $PSScriptRoot
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
if (-not $LogDir) { $LogDir = Join-Path $env:TEMP ("bravi-verify\" + (Get-Date -Format 'yyyyMMdd-HHmmss')) }
New-Item -ItemType Directory -Force -Path $LogDir | Out-Null
Write-Output "logs: $LogDir"

$steps = @('tests', 'smoke', 'opponent', 'ui', 'pattern', 'counter')
if ($Stats) { $steps += @('stats', 'reach', 'partstats', 'tierwrong', 'tierclean', 'spar', 'sparwrong', 'sparparry', 'court', 'courtwrong', 'courtnaive', 'noble', 'noblewrong', 'pairhat', 'pairhatwrong', 'pairspar', 'pairsparclean', 'afterhand', 'hold', 'holdwrong', 'holdrash', 'sleeve', 'dunhead') }
if ($Only) { $steps = @($Only -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ }) }

$errorPattern = '^\s*(USER |)(SCRIPT |SHADER |)ERROR'
$started = Get-Date
# The first import may log font errors while the theme loads: import twice, judge the second.
cmd /c "`"$Godot`" --headless --path `"$project`" --import 2>&1" | Out-Null
$import = cmd /c "`"$Godot`" --headless --path `"$project`" --import 2>&1"
$importExit = $LASTEXITCODE
$import | Set-Content -Encoding UTF8 -Path (Join-Path $LogDir 'import.log')
$importErrors = @($import | Where-Object { $_ -match $errorPattern -or $_ -match 'leaked|Parse Error' })
if ($importExit -ne 0 -or $importErrors.Count -gt 0) {
	$importErrors | Select-Object -First 30 | ForEach-Object { Write-Output "  $_" }
	Write-Output "import: FAIL (exit code $importExit, error lines $($importErrors.Count))"
	Write-Output 'VERIFY: FAIL (import)'
	exit 1
}
Write-Output 'import: OK'

$scripts = @{
	tests = 'run_tests.ps1'; smoke = 'run_smoke.ps1'; opponent = 'run_opponent_shots.ps1'
	ui = 'run_ui_shots.ps1'; pattern = 'run_pattern_shots.ps1'; stats = 'run_duel_stats.ps1'
	reach = 'run_part_reach.ps1'; counter = 'run_part_counter_shots.ps1'; partstats = 'run_duel_stats.ps1'
	tierwrong = 'run_duel_stats.ps1'; tierclean = 'run_duel_stats.ps1'
	spar = 'run_duel_stats.ps1'; sparwrong = 'run_duel_stats.ps1'; sparparry = 'run_duel_stats.ps1'
	court = 'run_duel_stats.ps1'; courtwrong = 'run_duel_stats.ps1'; courtnaive = 'run_duel_stats.ps1'; noble = 'run_duel_stats.ps1'; noblewrong = 'run_duel_stats.ps1'
	pairhat = 'run_duel_stats.ps1'; pairhatwrong = 'run_duel_stats.ps1'; pairspar = 'run_duel_stats.ps1'; pairsparclean = 'run_duel_stats.ps1'; afterhand = 'run_duel_stats.ps1'
	hold = 'run_duel_stats.ps1'; holdwrong = 'run_duel_stats.ps1'; holdrash = 'run_duel_stats.ps1'; sleeve = 'run_duel_stats.ps1'; dunhead = 'run_duel_stats.ps1'
}
$extra = @{
	# Small tier set (plan 040 decision 593): every opponent's last tier; a bot that misjudges heights and one that does not.
	tierwrong = @('-Tier', 'last', '-Opening', '3', '-Nine', '-Miss', '0.1')
	tierclean = @('-Tier', 'last', '-Opening', '3', '-Nine')
	partstats = @('-Opponent', 'res://data/opponents/opponent_01.tres', '-Opening', '1', '-Effects', 'off,on', '-Counter', 'thrust,arm,low', '-Nine')
	# Plan 043 decision 662: the spar commission on day 4 (opening 3) with a bot that never strikes a staggered opponent. sparparry has no band: it only reports.
	spar = @('-Commission', 'res://data/commissions/spar.tres', '-Opening', '3', '-Nine', '-Finisher', 'off', '-Runs', '60')
	sparwrong = @('-Commission', 'res://data/commissions/spar.tres', '-Opening', '3', '-Nine', '-Finisher', 'off', '-Runs', '60', '-Miss', '0.1')
	sparparry = @('-Commission', 'res://data/commissions/spar.tres', '-Opening', '3', '-Nine', '-Finisher', 'off', '-Runs', '60', '-Guard', 'parry', '-Jitter', '0')
	# Plan 046 decision 741: day 5 (opening 3). court = chest-only court errand, courtwrong adds -Miss 0.1, courtnaive strikes back at the guarded cell (-Counter same: the evidence for decision 735). noble = leg-only noble errand with a bot that finishes low, noblewrong adds -Miss 0.1.
	court = @('-Commission', 'res://data/commissions/variants/court_beehive.tres', '-Opening', '3', '-Nine', '-Runs', '60')
	courtwrong = @('-Commission', 'res://data/commissions/variants/court_beehive.tres', '-Opening', '3', '-Nine', '-Runs', '60', '-Miss', '0.1')
	courtnaive = @('-Commission', 'res://data/commissions/variants/court_beehive.tres', '-Opening', '3', '-Nine', '-Runs', '60', '-Counter', 'same')
	noble = @('-Commission', 'res://data/commissions/variants/noble_baker.tres', '-Opening', '3', '-Nine', '-Runs', '60', '-Finisher', 'low')
	noblewrong = @('-Commission', 'res://data/commissions/variants/noble_baker.tres', '-Opening', '3', '-Nine', '-Runs', '60', '-Finisher', 'low', '-Miss', '0.1')
	# Plan 047 decision 760: day 6-7 (opening 3). pairhat = hat errand (finisher top: the sword-side slash in the top row), pairhatwrong adds -Miss 0.1, pairspar = spar with a bot fooled by feints (-Bite 0.3), pairsparclean is the same bot never fooled (no band), afterhand = sword-hand errand at sword-style tier 2 (-Dive retreat).
	pairhat = @('-Commission', 'res://data/commissions/variants/pair_hatter.tres', '-Opening', '3', '-Nine', '-Runs', '60', '-Finisher', 'top')
	pairhatwrong = @('-Commission', 'res://data/commissions/variants/pair_hatter.tres', '-Opening', '3', '-Nine', '-Runs', '60', '-Finisher', 'top', '-Miss', '0.1')
	pairspar = @('-Commission', 'res://data/commissions/variants/pair_baker.tres', '-Opening', '3', '-Nine', '-Runs', '60', '-Finisher', 'off', '-Bite', '0.3')
	pairsparclean = @('-Commission', 'res://data/commissions/variants/pair_baker.tres', '-Opening', '3', '-Nine', '-Runs', '60', '-Finisher', 'off')
	afterhand = @('-Commission', 'res://data/commissions/variants/after_hatter.tres', '-Opening', '3', '-Nine', '-Runs', '60', '-Finisher', 'top', '-Dive', 'retreat', '-Tier', '2')
	# Plan 048 decision 778: day 4-6 (opening 3). hold = the patient bot on the hold errand at Bruno tier 2 (-Tier 2, the line name is opponent_02-t2), holdwrong adds -Miss 0.1, holdrash is the same without -Patient (counters at once: early touches cost points), sleeve = sword-arm errand (finisher arm, -Bite 0.3), dunhead = head errand at Agostino tier 2 (finisher head). They print stat, score, hold and parts lines.
	hold = @('-Commission', 'res://data/commissions/variants/close_baker.tres', '-Tier', '2', '-Opening', '3', '-Nine', '-Runs', '60', '-Patient')
	holdwrong = @('-Commission', 'res://data/commissions/variants/close_baker.tres', '-Tier', '2', '-Opening', '3', '-Nine', '-Runs', '60', '-Patient', '-Miss', '0.1')
	holdrash = @('-Commission', 'res://data/commissions/variants/close_baker.tres', '-Tier', '2', '-Opening', '3', '-Nine', '-Runs', '60')
	sleeve = @('-Commission', 'res://data/commissions/variants/rival_milliner.tres', '-Opening', '3', '-Nine', '-Runs', '60', '-Finisher', 'arm', '-Bite', '0.3')
	dunhead = @('-Commission', 'res://data/commissions/variants/dun_master.tres', '-Opening', '3', '-Nine', '-Runs', '60', '-Finisher', 'head', '-Tier', '2')
}
$failed = @()
foreach ($step in $steps) {
	if (-not $scripts.ContainsKey($step)) {
		Write-Output "${step}: FAIL (unknown step; known: $($scripts.Keys -join ', '))"
		$failed += $step
		continue
	}
	$stepArgs = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', (Join-Path $PSScriptRoot $scripts[$step]), '-SkipImport', '-Godot', $Godot)
	if ($Shots -and @('opponent', 'ui', 'pattern', 'counter') -contains $step) { $stepArgs += @('-Shots', (Join-Path $Shots $step)) }
	if ($extra.ContainsKey($step)) { $stepArgs += $extra[$step] }
	$stepStart = Get-Date
	$out = & powershell @stepArgs
	$code = $LASTEXITCODE
	$out | Set-Content -Encoding UTF8 -Path (Join-Path $LogDir "$step.log")
	$seconds = [int]((Get-Date) - $stepStart).TotalSeconds
	$result = @($out | Where-Object { $_ -match '^RESULT:' }) | Select-Object -Last 1
	if (-not $result) { $result = 'RESULT: (none)' }
	if ($code -ne 0) {
		$failed += $step
		$out | Where-Object { $_ -match 'FAIL|ERROR|Parse Error|leaked' -and $_ -notmatch '^RESULT:' } | Select-Object -First 30 | ForEach-Object { Write-Output "  $_" }
	}
	Write-Output "${step}: $($result -replace '^RESULT:\s*', '') [${seconds}s]"
	if ($step -eq 'pattern') { $out | Where-Object { $_ -match '^overlap,' } | Select-Object -First 60 | ForEach-Object { Write-Output "  $_" } }
	if ($step -eq 'counter') { $out | Where-Object { $_ -match '^(overlap|counter),' } | ForEach-Object { Write-Output "  $_" } }
	if ($step -eq 'stats') { $out | Where-Object { $_ -match '^(stat|routes),' } | ForEach-Object { Write-Output "  $_" } }
	if (@('partstats', 'tierwrong', 'tierclean') -contains $step) { $out | Where-Object { $_ -match '^stat,' } | ForEach-Object { Write-Output "  $_" } }
	# The spar and court/noble steps print the "score," lines too ("parts," only exists for a target-part commission).
	if (@('spar', 'sparwrong', 'sparparry', 'court', 'courtwrong', 'courtnaive', 'noble', 'noblewrong', 'pairhat', 'pairhatwrong', 'pairspar', 'pairsparclean', 'afterhand', 'hold', 'holdwrong', 'holdrash', 'sleeve', 'dunhead') -contains $step) { $out | Where-Object { $_ -match '^(stat|score|parts|hold),' } | ForEach-Object { Write-Output "  $_" } }
	if ($step -eq 'reach') { $out | Where-Object { $_ -match '^reach,' } | ForEach-Object { Write-Output "  $_" } }
}

$total = [int]((Get-Date) - $started).TotalSeconds
if ($Shots) { Write-Output "shots: $Shots" }
if ($failed.Count -eq 0) {
	Write-Output "VERIFY: OK ($($steps -join ', ')) [${total}s]"
	exit 0
}
Write-Output "VERIFY: FAIL ($($failed -join ', ')) [${total}s]"
exit 1
