# Finds the Godot console executable. (ASCII only: Windows PowerShell 5.1 reads BOM-less files as ANSI.)
#
#   . "$PSScriptRoot\godot_path.ps1"
#   $Godot = Find-Godot $Godot
#
# Order: the explicit path (-Godot argument), else the GODOT environment variable, else the
# candidates below. An explicit or GODOT path that does not exist is NOT skipped: the result is
# returned as-is so the caller fails on it (a wrong path must not be swallowed silently).
# Returns the path, or the last thing tried when nothing exists. The caller checks Test-Path.
function Find-Godot {
	param([string]$Explicit)

	if ($Explicit) { return $Explicit }
	if ($env:GODOT) { return $env:GODOT }

	$candidates = @(
		'C:\godot\Godot_v4.7.2-stable_win64_console.exe',
		# The zip extracted on the desktop: the folder name itself ends in ".exe".
		(Join-Path $env:USERPROFILE 'Desktop\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe')
	)
	foreach ($candidate in $candidates) {
		if (Test-Path -LiteralPath $candidate -PathType Leaf) { return $candidate }
	}
	return $candidates[0]
}
