# Manuscript UI shots (plan 033 task 7). (ASCII only: Windows PowerShell 5.1 reads BOM-less files as ANSI.)
#
#   powershell -ExecutionPolicy Bypass -File tests/run_ui_shots.ps1 -Shots "$env:TEMP\bravi-033-ui"
#   powershell -ExecutionPolicy Bypass -File tests/run_ui_shots.ps1 -Shots "$env:TEMP\bravi-033-ui-1600" -Resolution 1600x900
#
# Runs tests/ui_shots.tscn: five shots that pair with the 025 sample (pair-*) and eleven more (16 shots).
# Judges the run: exit code 0, one "UI SHOTS OK 16" line, no ERROR lines, sixteen "size," lines all equal to the
# resolution (1280x720 without -Resolution). "state," lines say how each scene was posed; they are not judged.
#
# Godot path: -Godot argument, else the GODOT environment variable, else the candidates in tests/godot_path.ps1.
param(
	# verify.ps1 imports once and passes this.
	[switch]$SkipImport,
	[string]$Godot,
	[string]$Shots,
	[string]$Resolution = ''
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
$count = 16

# The first import may log errors while the project theme reads fonts that are not imported yet: import twice, judge the second.
if (-not $SkipImport) { cmd /c "`"$Godot`" --headless --path `"$project`" --import 2>&1" | Out-Null }
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

$resArg = if ($Resolution) { "--resolution $Resolution" } else { '' }
$wantSize = if ($Resolution) { $Resolution } else { '1280x720' }
if ($Shots) {
	New-Item -ItemType Directory -Force -Path $Shots | Out-Null
	$out = cmd /c "`"$Godot`" --path `"$project`" $resArg res://tests/ui_shots.tscn --quit-after 20000 -- `"--shots=$Shots`" 2>&1"
} else {
	$out = cmd /c "`"$Godot`" --headless --path `"$project`" res://tests/ui_shots.tscn --quit-after 20000 2>&1"
}
$runExit = $LASTEXITCODE
$out | ForEach-Object { Write-Output $_ }

$errors = @($out | Where-Object { $_ -match $errorPattern })
$warnings = @($out | Where-Object { $_ -match '^\s*WARNING:' })
$ok = @($out | Where-Object { $_ -match "^UI SHOTS OK $count`$" })
$sizes = @($out | Where-Object { $_ -match '^size,' })
$badSize = @($sizes | Where-Object { ($_ -split ',')[2] -ne $wantSize })

$reasons = @()
if ($runExit -ne 0) { $reasons += "exit code $runExit" }
if ($ok.Count -ne 1) { $reasons += "no `"UI SHOTS OK $count`" line" }
if ($errors.Count -gt 0) { $reasons += "error lines $($errors.Count)" }
if ($sizes.Count -ne $count -or $badSize.Count -gt 0) { $reasons += "size lines $($sizes.Count), not $wantSize $($badSize.Count)" }

# Plan 037 task 0b: the practice grid must fit 1280x720 (right edge <= 1248, help text bottom <= 720). Not judged with -Resolution.
$fit = @($out | Where-Object { $_ -match '^fit,select,' })
$fitNote = 'fit none'
if ($fit.Count -eq 1) {
	$fitParts = $fit[0] -split ','
	$fitX = [int]$fitParts[2]
	$fitY = [int]$fitParts[3]
	$fitNote = "fit select ${fitX}x${fitY}"
	if (-not $Resolution -and ($fitX -gt 1248 -or $fitY -gt 720)) { $reasons += "fit select ${fitX}x${fitY} (limit 1248x720)" }
} elseif (-not $Resolution) {
	$reasons += "fit,select lines $($fit.Count), not 1"
}

Write-Output ''
if ($reasons.Count -eq 0) {
	Write-Output "RESULT: OK ($($ok[0]), $wantSize, $fitNote, error lines 0, warning lines $($warnings.Count))"
	exit 0
}
Write-Output "RESULT: FAIL ($($reasons -join ', '))"
exit 1
