# Player hand shots (plan 032 task 9). (ASCII only: Windows PowerShell 5.1 reads BOM-less files as ANSI.)
#
#   powershell -ExecutionPolicy Bypass -File tests/run_hand_shots.ps1 -Shots "$env:TEMP\bravi-032-shots"
#   powershell -ExecutionPolicy Bypass -File tests/run_hand_shots.ps1 -Shots "$env:TEMP\bravi-032-shots-1920" -Resolution 1920x1080
#
# Runs tests/hand_shots.tscn: the duel scene (feather_cut, alley) held still, the player's sword state set by hand, 15 shots.
# Judges the run: exit code 0, one "HAND SHOTS OK 15" line, no ERROR lines, fifteen "hand," lines all with y1 >= 720
# (the sleeve end is below the screen), fifteen "bind," lines with only the bind warning shot "true".
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
	$out = cmd /c "`"$Godot`" --path `"$project`" $resArg res://tests/hand_shots.tscn --quit-after 20000 -- `"--shots=$Shots`" 2>&1"
} else {
	$out = cmd /c "`"$Godot`" --headless --path `"$project`" res://tests/hand_shots.tscn --quit-after 20000 2>&1"
}
$runExit = $LASTEXITCODE
$out | ForEach-Object { Write-Output $_ }

$errors = @($out | Where-Object { $_ -match $errorPattern })
$warnings = @($out | Where-Object { $_ -match '^\s*WARNING:' })
$ok = @($out | Where-Object { $_ -match '^HAND SHOTS OK 15$' })
$hands = @($out | Where-Object { $_ -match '^hand,' })
$badHand = @($hands | Where-Object { [double](($_ -split ',')[5]) -lt 720 })
$binds = @($out | Where-Object { $_ -match '^bind,' })
$badBind = @($binds | Where-Object { $q = $_ -split ','; ($q[1] -like 'bind-warning*') -ne ($q[2] -eq 'true') })

$reasons = @()
if ($runExit -ne 0) { $reasons += "exit code $runExit" }
if ($ok.Count -ne 1) { $reasons += 'no "HAND SHOTS OK 15" line' }
if ($errors.Count -gt 0) { $reasons += "error lines $($errors.Count)" }
if ($hands.Count -ne 15 -or $badHand.Count -gt 0) { $reasons += "hand lines $($hands.Count), sleeve end above 720 $($badHand.Count)" }
if ($binds.Count -ne 15 -or $badBind.Count -gt 0) { $reasons += "bind lines $($binds.Count), wrong $($badBind.Count)" }

Write-Output ''
if ($reasons.Count -eq 0) {
	Write-Output "RESULT: OK ($($ok[0]), $wantSize, error lines 0, warning lines $($warnings.Count))"
	exit 0
}
Write-Output "RESULT: FAIL ($($reasons -join ', '))"
exit 1