# Pattern ring shots. (ASCII only: Windows PowerShell 5.1 reads BOM-less files as ANSI.)
#
#   powershell -ExecutionPolicy Bypass -File tests/run_pattern_shots.ps1                     (headless: overlap lines only)
#   powershell -ExecutionPolicy Bypass -File tests/run_pattern_shots.ps1 -Shots "$env:TEMP\bravi-pattern"
#   powershell -ExecutionPolicy Bypass -File tests/run_pattern_shots.ps1 -Commission res://data/commissions/feather_cut.tres  (that commission's HUD and hat)
#
# Runs tests/pattern_shots.tscn: every day-opponent pattern, every route (base and variants), three distances.
# Prints "shot," lines (what was posed) and "overlap," lines (a numbered ring over a HUD panel or label).
# Judges the run: exit code 0, one "PATTERN SHOTS OK <n>" line, no ERROR lines. Overlaps are reported, not judged.
param(
	[switch]$SkipImport,
	[string]$Godot,
	[string]$Shots,
	[string]$Commission = ""
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

$commissionArg = ""
$headlessArgs = ""
if ($Commission) { $commissionArg = " `"--commission=$Commission`""; $headlessArgs = " --$commissionArg" }
if ($Shots) {
	New-Item -ItemType Directory -Force -Path $Shots | Out-Null
	$out = cmd /c "`"$Godot`" --path `"$project`" res://tests/pattern_shots.tscn --quit-after 20000 -- `"--shots=$Shots`"$commissionArg 2>&1"
} else {
	$out = cmd /c "`"$Godot`" --headless --path `"$project`" res://tests/pattern_shots.tscn --quit-after 20000$headlessArgs 2>&1"
}
$runExit = $LASTEXITCODE
$out | ForEach-Object { Write-Output $_ }

$errors = @($out | Where-Object { $_ -match $errorPattern })
$ok = @($out | Where-Object { $_ -match '^PATTERN SHOTS OK \d+$' })
$overlaps = @($out | Where-Object { $_ -match '^overlap,' })

$reasons = @()
if ($runExit -ne 0) { $reasons += "exit code $runExit" }
if ($ok.Count -ne 1) { $reasons += 'no "PATTERN SHOTS OK" line' }
if ($errors.Count -gt 0) { $reasons += "error lines $($errors.Count)" }

Write-Output ''
if ($reasons.Count -eq 0) {
	Write-Output "RESULT: OK ($($ok[0]), overlap lines $($overlaps.Count), error lines 0)"
	exit 0
}
Write-Output "RESULT: FAIL ($($reasons -join ', '))"
exit 1
