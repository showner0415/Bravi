# Feel shots (plan H03 task 1). (ASCII only: Windows PowerShell 5.1 reads BOM-less files as ANSI.)
#
#   powershell -ExecutionPolicy Bypass -File tests/run_feel_shots.ps1 -Group A,B,C -Shots "$env:TEMP\bravi-h03-shots"
#
# Runs tests/feel_shots.tscn (the duel scene, physics off, stepped with advance). Groups: A = my attack step by step (25 shots),
# B = the contact frame of 9 cells x engage/close + 3 lunges (21), C = results and short whiffs (16). No -Group = all (62).
# Prints one "feel,<name>,dist=..,move=..,kink=..,scale=..,sleeve=..,PASS|FAIL" line per shot.
# Judges the run: exit code 0, one "FEEL SHOTS OK <n>" line, no ERROR lines, n feel lines all PASS. Without -Shots no PNG is saved (headless).
param(
	[switch]$SkipImport,
	[string]$Godot,
	[string]$Shots,
	[string]$Group = ''
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

$counts = @{ A = 25; B = 21; C = 16 }
$groups = if ($Group) { @($Group -split ',' | ForEach-Object { $_.Trim().ToUpper() } | Where-Object { $_ }) } else { @('A', 'B', 'C') }
$expected = 0
foreach ($g in $groups) { if ($counts.ContainsKey($g)) { $expected += $counts[$g] } }
$groupArg = if ($Group) { "`"--group=$Group`"" } else { '' }

if ($Shots) {
	New-Item -ItemType Directory -Force -Path $Shots | Out-Null
	$out = cmd /c "`"$Godot`" --path `"$project`" res://tests/feel_shots.tscn --quit-after 60000 -- `"--shots=$Shots`" $groupArg 2>&1"
} else {
	$out = cmd /c "`"$Godot`" --headless --path `"$project`" res://tests/feel_shots.tscn --quit-after 60000 -- $groupArg 2>&1"
}
$runExit = $LASTEXITCODE
$out | ForEach-Object { Write-Output $_ }

$errors = @($out | Where-Object { $_ -match $errorPattern })
$warnings = @($out | Where-Object { $_ -match '^\s*WARNING:' })
$ok = @($out | Where-Object { $_ -match "^FEEL SHOTS OK $expected$" })
$lines = @($out | Where-Object { $_ -match '^feel,' })
$bad = @($lines | Where-Object { $_ -notmatch ',PASS$' })

$reasons = @()
if ($runExit -ne 0) { $reasons += "exit code $runExit" }
if ($ok.Count -ne 1) { $reasons += "no `"FEEL SHOTS OK $expected`" line" }
if ($errors.Count -gt 0) { $reasons += "error lines $($errors.Count)" }
if ($lines.Count -ne $expected -or $bad.Count -gt 0) { $reasons += "feel lines $($lines.Count) (want $expected), not PASS $($bad.Count)" }

Write-Output ''
if ($reasons.Count -eq 0) {
	Write-Output "RESULT: OK ($($ok[0]), error lines 0, warning lines $($warnings.Count))"
	exit 0
}
Write-Output "RESULT: FAIL ($($reasons -join ', '))"
exit 1
