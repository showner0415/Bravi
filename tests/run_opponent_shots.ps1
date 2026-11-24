# Opponent art shots (plan 029, task 8). (ASCII only: Windows PowerShell 5.1 reads BOM-less files as ANSI.)
#
#   powershell -ExecutionPolicy Bypass -File tests/run_opponent_shots.ps1 -Shots "$env:TEMP\bravi-029-shots"
#   powershell -ExecutionPolicy Bypass -File tests/run_opponent_shots.ps1            (headless, saves nothing)
#
# Runs tests/opponent_shots.tscn: the opponent view alone, one PNG per state (57; plan 029 41 + plan 030 16).
# -Sil: silhouette mode (28 shots: arm blue, head red, body grey, white ground) for R1/R2/R4 (plan 030 decision 270).
# With -Shots it opens a window (the shots need a renderer) and also writes the measuring points
# (lines starting "pt,") to <Shots>\pts.txt.
# Judges the run: exit code 0, the last "OPPONENT SHOTS OK <n>" line, and no ERROR / SHADER ERROR lines.
#
# Godot path: -Godot argument, else the GODOT environment variable, else the candidates in
# tests/godot_path.ps1.
param(
	# verify.ps1 imports once and passes this.
	[switch]$SkipImport,
	[string]$Godot,
	[string]$Shots,
	[switch]$Sil,
	[switch]$Stages,
	[string]$Opponent
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
$import = @()
$importExit = 0
if (-not $SkipImport) {
	$import = cmd /c "`"$Godot`" --headless --path `"$project`" --import 2>&1"
	$importExit = $LASTEXITCODE
}
$importErrors = @($import | Where-Object { $_ -match $errorPattern })
if ($importExit -ne 0 -or $importErrors.Count -gt 0) {
	$importErrors | ForEach-Object { Write-Output $_ }
	Write-Output "RESULT: FAIL (import step: exit code $importExit, error lines $($importErrors.Count))"
	exit 1
}

if ($Sil -and $Stages) {
	Write-Output "RESULT: FAIL (-Sil and -Stages cannot go together)"
	exit 1
}
# -Stages: the opponent on the three duel stages, 21 shots (plan 031 decision 300).
$silArg = if ($Sil) { '--sil' } elseif ($Stages) { '--stages' } else { '' }
# Plan 035 decision 364: -Opponent res://data/opponents/opponent_02.tres shoots that opponent (empty = Bartolo).
if ($Opponent) { $silArg = "$silArg --opponent=$Opponent" }
$expected = if ($Sil) { 28 } elseif ($Stages) { 21 } else { 57 }
if ($Shots) {
	New-Item -ItemType Directory -Force -Path $Shots | Out-Null
	$out = cmd /c "`"$Godot`" --path `"$project`" res://tests/opponent_shots.tscn --quit-after 6000 -- `"--shots=$Shots`" $silArg 2>&1"
} else {
	$out = cmd /c "`"$Godot`" --headless --path `"$project`" res://tests/opponent_shots.tscn --quit-after 6000 -- $silArg 2>&1"
}
$runExit = $LASTEXITCODE
$out | ForEach-Object { Write-Output $_ }
if ($Shots -and -not $Sil -and -not $Stages) {
	$out | Where-Object { $_ -match '^pt,' } | Set-Content -Encoding ASCII -Path (Join-Path $Shots 'pts.txt')
}
if ($Shots -and $Stages) {
	$out | Where-Object { $_ -match '^ext,' } | Set-Content -Encoding ASCII -Path (Join-Path $Shots 'ext.txt')
}

$errors = @($out | Where-Object { $_ -match $errorPattern })
$warnings = @($out | Where-Object { $_ -match '^\s*WARNING:' })
$ok = @($out | Where-Object { $_ -match "^OPPONENT SHOTS OK $expected`$" })

$reasons = @()
if ($runExit -ne 0) { $reasons += "exit code $runExit" }
if ($ok.Count -ne 1) { $reasons += "no `"OPPONENT SHOTS OK $expected`" line" }
if ($errors.Count -gt 0) { $reasons += "error lines $($errors.Count)" }

Write-Output ''
if ($reasons.Count -eq 0) {
	Write-Output "RESULT: OK ($($ok[0]), error lines 0, warning lines $($warnings.Count))"
	exit 0
}
Write-Output "RESULT: FAIL ($($reasons -join ', '))"
exit 1
