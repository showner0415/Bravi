# Test turn queue shared by every Claude session on this machine (user rule 2026-11-28):
# if another session is running tests, wait until it ends; when two or more sessions wait,
# the one that started waiting first goes first. (ASCII only: Windows PowerShell 5.1.)
#
#   powershell -ExecutionPolicy Bypass -File C:\godot\bravi\tests\wait_turn.ps1 -Name <session-label>
#       Takes a ticket (once) and waits until this ticket is the oldest AND no Godot test process of
#       another worktree is running. Prints "TURN <name>" and exits 0. Keep the ticket while you run
#       your whole batch of tests; other sessions wait for you.
#       If -MaxWaitSec passes first, prints "STILL WAITING <name> (ahead: ...)" and exits 2; call it
#       again with the same -Name (the ticket and its place in line are kept).
#   powershell -ExecutionPolicy Bypass -File C:\godot\bravi\tests\wait_turn.ps1 -Name <session-label> -Release
#       Removes the ticket. Always release when the batch ends (also after a failure).
#   ... -Status       prints the queue and the running Godot test processes, changes nothing.
#
# The queue lives outside every worktree: C:\godot\.bravi-test-queue (one file per waiting session,
# named by the time it joined). A Godot test process is one whose command line has "res://tests/".
# Call it before the first command of a batch, not between your own commands (your own Godot would block you).
# A game window started for play has no "res://tests/" and never blocks anyone.
# A ticket older than -StaleMin minutes whose owner runs no Godot test is treated as abandoned.
param(
	[string]$Name = '',
	[switch]$Release,
	[switch]$Status,
	[int]$MaxWaitSec = 540,
	[int]$PollSec = 10,
	[int]$StaleMin = 180
)

$queue = 'C:\godot\.bravi-test-queue'
New-Item -ItemType Directory -Force -Path $queue | Out-Null

function Get-TestProcs {
	@(Get-CimInstance Win32_Process | Where-Object {
		$_.Name -match 'odot' -and $_.CommandLine -and $_.CommandLine -match 'res://tests/'
	})
}

function Get-Tickets {
	@(Get-ChildItem -LiteralPath $queue -Filter '*.ticket' -ErrorAction SilentlyContinue | Sort-Object Name)
}

function Get-Worktree([string]$cmd) {
	if ($cmd -match '--path\s+"([^"]+)"') { return $Matches[1] }
	if ($cmd -match '--path\s+(\S+)') { return $Matches[1] }
	return '?'
}

function Show-State {
	Write-Output 'queue (oldest first):'
	foreach ($t in Get-Tickets) { Write-Output ("  {0}  {1}" -f $t.Name, (Get-Content -LiteralPath $t.FullName -Raw).Trim()) }
	Write-Output 'running Godot test processes:'
	foreach ($p in Get-TestProcs) { Write-Output ("  pid {0}  {1}" -f $p.ProcessId, (Get-Worktree $p.CommandLine)) }
}

if ($Status) { Show-State; exit 0 }
if ($Name -eq '') { Write-Output 'RESULT: FAIL (-Name is required)'; exit 1 }
$safe = ($Name -replace '[^A-Za-z0-9_.-]', '_')

$mine = @(Get-Tickets | Where-Object { $_.Name -like "*-$safe.ticket" })
if ($Release) {
	$mine | ForEach-Object { Remove-Item -LiteralPath $_.FullName -Force }
	Write-Output "RELEASED $safe ($($mine.Count) ticket)"
	exit 0
}

if ($mine.Count -eq 0) {
	$stamp = (Get-Date).ToUniversalTime().ToString('yyyyMMddHHmmssfff')
	$path = Join-Path $queue "$stamp-$safe.ticket"
	Set-Content -LiteralPath $path -Value ("{0} joined {1} from {2}" -f $safe, (Get-Date -Format 's'), (Get-Location).Path) -Encoding ascii
	Write-Output "TICKET $stamp-$safe"
} else {
	$path = $mine[0].FullName
}
$deadline = (Get-Date).AddSeconds($MaxWaitSec)
while ($true) {
	$procs = Get-TestProcs
	# Any running Godot test blocks: the caller has not started its own batch yet, and another session
	# may share this worktree.
	$foreign = $procs
	# Abandoned tickets: old and no Godot test runs at all.
	foreach ($t in Get-Tickets) {
		if ($t.FullName -ne $path -and $t.LastWriteTime -lt (Get-Date).AddMinutes(-$StaleMin) -and $procs.Count -eq 0) {
			Remove-Item -LiteralPath $t.FullName -Force
			Write-Output "STALE ticket removed: $($t.Name)"
		}
	}
	$tickets = Get-Tickets
	$ahead = @($tickets | Where-Object { $_.Name -lt (Split-Path $path -Leaf) })
	if ($ahead.Count -eq 0 -and $foreign.Count -eq 0) {
		# Touch so a long batch is not mistaken for an abandoned ticket.
		(Get-Item -LiteralPath $path).LastWriteTime = Get-Date
		Write-Output "TURN $safe"
		exit 0
	}
	if ((Get-Date) -gt $deadline) {
		(Get-Item -LiteralPath $path).LastWriteTime = Get-Date
		$names = ($ahead | ForEach-Object { $_.Name }) -join ', '
		Write-Output "STILL WAITING $safe (ahead: $names; foreign Godot tests: $($foreign.Count))"
		exit 2
	}
	Start-Sleep -Seconds $PollSec
}
