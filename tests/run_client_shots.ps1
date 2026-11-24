# Client counter shots (plan 034 decision 355). (ASCII only: Windows PowerShell 5.1 reads BOM-less files as ANSI.)
#
#   powershell -ExecutionPolicy Bypass -File tests/run_client_shots.ps1 -Shots "$env:TEMP\bravi-034-clients"
#   powershell -ExecutionPolicy Bypass -File tests/run_client_shots.ps1 -Shots "$env:TEMP\bravi-034-clients-1600" -Resolution 1600x900
#
# Runs tests/client_shots.tscn: one counter shot per commission, after the client has slid in (7 shots).
# Judges the run: exit code 0, one "CLIENT SHOTS OK 7" line, no ERROR lines, seven "size," lines all equal to the
# resolution (1280x720 without -Resolution), and seven "portrait," boxes within 2 px of (80, 120) 300x450 (decision 346).
#
# Godot path: -Godot argument, else the GODOT environment variable, else the candidates in tests/godot_path.ps1.
param(
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
$count = 7

# The first import may log errors while the project theme reads fonts that are not imported yet: import twice, judge the second.
cmd /c "`"$Godot`" --headless --path `"$project`" --import 2>&1" | Out-Null
$import = cmd /c "`"$Godot`" --headless --path `"$project`" --import 2>&1"
$importExit = $LASTEXITCODE
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
	$out = cmd /c "`"$Godot`" --path `"$project`" $resArg res://tests/client_shots.tscn --quit-after 20000 -- `"--shots=$Shots`" 2>&1"
} else {
	$out = cmd /c "`"$Godot`" --headless --path `"$project`" res://tests/client_shots.tscn --quit-after 20000 2>&1"
}
$runExit = $LASTEXITCODE
$out | ForEach-Object { Write-Output $_ }

$errors = @($out | Where-Object { $_ -match $errorPattern })
$warnings = @($out | Where-Object { $_ -match '^\s*WARNING:' })
$ok = @($out | Where-Object { $_ -match "^CLIENT SHOTS OK $count`$" })
$sizes = @($out | Where-Object { $_ -match '^size,' })
$badSize = @($sizes | Where-Object { ($_ -split ',')[2] -ne $wantSize })
$boxes = @($out | Where-Object { $_ -match '^portrait,' })
$badBox = @($boxes | Where-Object { $p = $_ -split ','; [math]::Abs([int]$p[2] - 80) -gt 2 -or [math]::Abs([int]$p[3] - 120) -gt 2 -or [math]::Abs([int]$p[4] - 300) -gt 2 -or [math]::Abs([int]$p[5] - 450) -gt 2 })

$reasons = @()
if ($runExit -ne 0) { $reasons += "exit code $runExit" }
if ($ok.Count -ne 1) { $reasons += "no `"CLIENT SHOTS OK $count`" line" }
if ($errors.Count -gt 0) { $reasons += "error lines $($errors.Count)" }
if ($sizes.Count -ne $count -or $badSize.Count -gt 0) { $reasons += "size lines $($sizes.Count), not $wantSize $($badSize.Count)" }
if ($boxes.Count -ne $count -or $badBox.Count -gt 0) { $reasons += "portrait lines $($boxes.Count), off the box $($badBox.Count)" }

Write-Output ''
if ($reasons.Count -eq 0) {
	Write-Output "RESULT: OK ($($ok[0]), $wantSize, error lines 0, warning lines $($warnings.Count))"
	exit 0
}
Write-Output "RESULT: FAIL ($($reasons -join ', '))"
exit 1
