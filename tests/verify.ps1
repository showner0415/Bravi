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
if ($Stats) { $steps += @('stats', 'reach', 'partstats') }
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
}
$extra = @{
	partstats = @('-Opponent', 'res://data/opponents/opponent_01.tres', '-Opening', '1', '-Effects', 'off,on', '-Counter', 'thrust,arm,low', '-Nine')
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
	if ($step -eq 'partstats') { $out | Where-Object { $_ -match '^stat,' } | ForEach-Object { Write-Output "  $_" } }
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
