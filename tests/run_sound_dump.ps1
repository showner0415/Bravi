# Sound dump. (ASCII only: Windows PowerShell 5.1 reads BOM-less files as ANSI.)
#
#   powershell -ExecutionPolicy Bypass -File tests/run_sound_dump.ps1 -Out "$env:TEMP\bravi-h03-sounds"
#
# Runs tests/sound_dump.gd headless: writes every sound key as <key>.wav (16-bit mono) plus four joined
# sequences (seq_touch, seq_ladder, seq_taken, seq_hit) into -Out, for listening outside the game.
# Judges the run: exit code 0, one "SOUND DUMP OK <n>" line, no ERROR lines.
param(
	[switch]$SkipImport,
	[string]$Godot,
	[string]$Out = ""
)

. "$PSScriptRoot\godot_path.ps1"
$Godot = Find-Godot $Godot
if (-not (Test-Path -LiteralPath $Godot -PathType Leaf)) {
	Write-Output "RESULT: FAIL (Godot not found: $Godot  -- pass -Godot <path> or set GODOT)"
	exit 1
}
if (-not $Out) { $Out = Join-Path $env:TEMP 'bravi-h03-sounds' }

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

New-Item -ItemType Directory -Force -Path $Out | Out-Null
$run = cmd /c "`"$Godot`" --headless --path `"$project`" --script res://tests/sound_dump.gd --quit-after 3000 -- `"--out=$Out`" 2>&1"
$runExit = $LASTEXITCODE
$run | ForEach-Object { Write-Output $_ }

$errors = @($run | Where-Object { $_ -match $errorPattern })
$ok = @($run | Where-Object { $_ -match '^SOUND DUMP OK \d+$' })

$reasons = @()
if ($runExit -ne 0) { $reasons += "exit code $runExit" }
if ($ok.Count -ne 1) { $reasons += 'no "SOUND DUMP OK" line' }
if ($errors.Count -gt 0) { $reasons += "error lines $($errors.Count)" }

Write-Output ''
if ($reasons.Count -eq 0) {
	Write-Output "RESULT: OK ($($ok[0]), out $Out)"
	exit 0
}
Write-Output "RESULT: FAIL ($($reasons -join ', '))"
exit 1
