# Duel stage shots for the HUD and the 1920 window (plan 031 task 7b, decision 300). (ASCII only: Windows PowerShell 5.1 reads BOM-less files as ANSI.)
#
#   powershell -ExecutionPolicy Bypass -File tests/run_stage_shots.ps1 -Shots "$env:TEMP\bravi-031-shots"
#   powershell -ExecutionPolicy Bypass -File tests/run_stage_shots.ps1 -Shots "$env:TEMP\bravi-031-shots-1920" -Resolution 1920x1080
#
# Runs tests/stage_shots.tscn: the duel scene for the three day-1 commissions, far / mid / close (9 shots).
# Judges the run: exit code 0, one "STAGE SHOTS OK 9" line, no ERROR lines, nine "size," lines all equal to the
# resolution (1280x720 without -Resolution), nine "scale," lines within 0.01 of the opponent view scale of that
# distance (far 0.55, mid 0.85, close 1.1: the distance tween has finished).
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
	$out = cmd /c "`"$Godot`" --path `"$project`" $resArg res://tests/stage_shots.tscn --quit-after 20000 -- `"--shots=$Shots`" 2>&1"
} else {
	$out = cmd /c "`"$Godot`" --headless --path `"$project`" res://tests/stage_shots.tscn --quit-after 20000 2>&1"
}
$runExit = $LASTEXITCODE
$out | ForEach-Object { Write-Output $_ }

$errors = @($out | Where-Object { $_ -match $errorPattern })
$warnings = @($out | Where-Object { $_ -match '^\s*WARNING:' })
$ok = @($out | Where-Object { $_ -match '^STAGE SHOTS OK 9$' })
$sizes = @($out | Where-Object { $_ -match '^size,' })
$badSize = @($sizes | Where-Object { ($_ -split ',')[2] -ne $wantSize })
$scales = @($out | Where-Object { $_ -match '^scale,' })
$want = @{ 'far' = 0.55; 'mid' = 0.85; 'close' = 1.1 }
$badScale = @($scales | Where-Object { $q = $_ -split ','; $d = ($q[1] -split '-')[-1]; -not $want.ContainsKey($d) -or [math]::Abs([double]$q[2] - $want[$d]) -gt 0.01 })

$reasons = @()
if ($runExit -ne 0) { $reasons += "exit code $runExit" }
if ($ok.Count -ne 1) { $reasons += 'no "STAGE SHOTS OK 9" line' }
if ($errors.Count -gt 0) { $reasons += "error lines $($errors.Count)" }
if ($sizes.Count -ne 9 -or $badSize.Count -gt 0) { $reasons += "size lines $($sizes.Count), not $wantSize $($badSize.Count)" }
if ($scales.Count -ne 9 -or $badScale.Count -gt 0) { $reasons += "scale lines $($scales.Count), off $($badScale.Count)" }

Write-Output ''
if ($reasons.Count -eq 0) {
	Write-Output "RESULT: OK ($($ok[0]), $wantSize, error lines 0, warning lines $($warnings.Count))"
	exit 0
}
Write-Output "RESULT: FAIL ($($reasons -join ', '))"
exit 1
