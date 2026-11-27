# Headless test wrapper. (ASCII only: Windows PowerShell 5.1 reads BOM-less files as ANSI.)
#
#   powershell -ExecutionPolicy Bypass -File tests/run_tests.ps1
#
# 1. Refreshes the class cache (.godot/ is not in git; a stale cache makes test files fail to parse).
# 2. Runs tests/run_tests.gd.
# 3. Judges the run: exit code 0, an "ALL PASS n/n" line, and no ERROR lines in the output.
#    All three are required. Exits 0 on pass, 1 on fail.
#
# Godot path: -Godot argument, else the GODOT environment variable, else the candidates in
# tests/godot_path.ps1.
param(
	# verify.ps1 imports once and passes this.
	[switch]$SkipImport,
	[string]$Godot,
	# Comma list of file-name fragments: run only those test files (split a run when memory is short).
	[string]$Only = ''
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
$errorPattern = '^\s*(USER |)(SCRIPT |)ERROR:'

# cmd merges stderr into stdout (PowerShell 5.1 would wrap stderr lines as error records).
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

$userArgs = ''
if ($Only -ne '') { $userArgs = " -- --only=$Only" }
$out = cmd /c "`"$Godot`" --headless --path `"$project`" --script res://tests/run_tests.gd --quit-after 6000$userArgs 2>&1"
$testExit = $LASTEXITCODE
$out | ForEach-Object { Write-Output $_ }

$errors = @($out | Where-Object { $_ -match $errorPattern })
$warnings = @($out | Where-Object { $_ -match '^\s*WARNING:' })
$allPass = @($out | Where-Object { $_ -match '^ALL PASS \d+/\d+\s*$' })

$reasons = @()
if ($testExit -ne 0) { $reasons += "exit code $testExit" }
if ($allPass.Count -ne 1) { $reasons += 'no "ALL PASS" line' }
if ($errors.Count -gt 0) { $reasons += "error lines $($errors.Count)" }

Write-Output ''
if ($reasons.Count -eq 0) {
	Write-Output "RESULT: OK ($($allPass[0].Trim()), error lines 0, warning lines $($warnings.Count))"
	exit 0
}
Write-Output "RESULT: FAIL ($($reasons -join ', '))"
exit 1
