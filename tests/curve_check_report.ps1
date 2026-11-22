# Reaction check report (plan 030, decision 273). (ASCII only: Windows PowerShell 5.1 reads BOM-less files as ANSI.)
#
#   powershell -ExecutionPolicy Bypass -File tests/curve_check_report.ps1                 (last session)
#   powershell -ExecutionPolicy Bypass -File tests/curve_check_report.ps1 -Session <value>
#
# Reads user://curve_check.csv (one row per opponent strike, written by scripts/duel/curve_check.gd) and prints,
# per curve (hold / flat) x (big cut / other): strikes, parried / blocked / hit counts and rates, median lead,
# and the late presses (a fresh guard within 0.3 s after the strike). Then the curve of each duel.
# "SUSPECT" marks a difference only when hold is worse by more than the threshold AND by 2 or more events
# (big-cut parry rate 15 points, late rate 10 points). The user's answer decides; the numbers only flag.
param(
	[string]$Path = (Join-Path $env:APPDATA 'Godot\app_userdata\Bravi\curve_check.csv'),
	[string]$Session = ''
)

if (-not (Test-Path -LiteralPath $Path)) {
	Write-Output "no record: $Path"
	exit 1
}
$rows = @(Import-Csv -LiteralPath $Path)
if (-not $Session) { $Session = ($rows | Select-Object -Last 1).session }
$rows = @($rows | Where-Object { $_.session -eq $Session })
Write-Output "session $Session, rows $($rows.Count)"

function Median([double[]]$v) {
	if ($v.Count -eq 0) { return '' }
	$s = $v | Sort-Object
	$m = [int][math]::Floor($s.Count / 2)
	if ($s.Count % 2 -eq 1) { return '{0:0.000}' -f $s[$m] }
	return '{0:0.000}' -f (($s[$m - 1] + $s[$m]) / 2)
}

$stats = @{}
foreach ($curve in 'hold', 'flat') {
	foreach ($kind in 'big', 'other') {
		$set = @($rows | Where-Object { $_.curve -eq $curve -and (($_.is_big -eq 'true') -eq ($kind -eq 'big')) })
		$n = $set.Count
		$parried = @($set | Where-Object { $_.result -eq 'PARRIED' }).Count
		$blocked = @($set | Where-Object { $_.result -eq 'BLOCKED' }).Count
		$hit = @($set | Where-Object { $_.result -eq 'GRAZE' -or $_.result -eq 'HIT' }).Count
		$late = @($set | Where-Object { $_.late -ne '' }).Count
		$leads = [double[]]@($set | Where-Object { $_.lead -ne '' } | ForEach-Object { [double]$_.lead })
		$d = [math]::Max(1, $n)
		$stats["$curve|$kind"] = @{ n = $n; parried = $parried; late = $late }
		Write-Output ('{0,-5} {1,-5} strikes {2,3}  parried {3,3} ({4,6:P0})  blocked {5,3}  hit {6,3}  lead median {7,6}  late {8,3} ({9,6:P0})' -f $curve, $kind, $n, $parried, ($parried / $d), $blocked, $hit, (Median $leads), $late, ($late / $d))
	}
	$b = $stats["$curve|big"]; $o = $stats["$curve|other"]
	$stats["$curve|all"] = @{ n = $b.n + $o.n; parried = $b.parried + $o.parried; late = $b.late + $o.late }
}

function Flag([string]$what, [string]$kind, [string]$field, [double]$limit, [bool]$higherIsWorse) {
	$h = $stats["hold|$kind"]; $f = $stats["flat|$kind"]
	if ($h.n -eq 0 -or $f.n -eq 0) { return }
	$rh = $h[$field] / $h.n; $rf = $f[$field] / $f.n
	$worse = if ($higherIsWorse) { $rh - $rf } else { $rf - $rh }
	# events: how many events the gap is worth at the smaller sample
	$events = [math]::Abs($worse) * [math]::Min($h.n, $f.n)
	$mark = if ($worse -gt $limit -and $events -ge 2) { 'SUSPECT' } else { 'ok' }
	Write-Output ('{0}: hold {1:P0} vs flat {2:P0}, gap {3:P0} (~{4:0.0} events) {5}' -f $what, $rh, $rf, $worse, $events, $mark)
}
Flag 'big-cut parry rate' 'big' 'parried' 0.15 $false
Flag 'late press rate (all)' 'all' 'late' 0.10 $true

Write-Output ''
Write-Output 'duel curves:'
$rows | Group-Object duel_id | Sort-Object { [int]$_.Name } | ForEach-Object { Write-Output ("  duel {0}: {1} ({2} strikes)" -f $_.Name, $_.Group[0].curve, $_.Count) }
