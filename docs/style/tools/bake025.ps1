param([string[]]$Shots, [switch]$DumpDom, [string]$DomQuery = '', [string]$DomOut = 'dom.html', [int]$Budget = 0, [string]$Page = '025-type-ui-size.html', [string]$OutDir = '025')
# shot: <id>[@<pick>][+<key>=<value>]... -> ?pick=<pick>&<key>=<value>...#<id>. One at a time, kill only Edge started with our profile.
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'paths.ps1')
$scratch = $BraviWork
$out = Join-Path $scratch $OutDir
$edgeProfile = Join-Path $scratch 'edge-profile'
New-Item -ItemType Directory -Force -Path $out, $edgeProfile | Out-Null
$edge = Get-ChildItem 'C:\Program Files (x86)\Microsoft\Edge\Application\*\msedge.exe' |
  Sort-Object { [version]$_.Directory.Name } -Descending | Select-Object -First 1 -ExpandProperty FullName
$pageUrl = "$BraviSamplesUrl$Page"
Add-Type -AssemblyName System.Drawing
function Stop-Ours {
  Get-CimInstance Win32_Process -Filter "Name='msedge.exe'" |
    Where-Object { $_.CommandLine -like "*$edgeProfile*" } |
    ForEach-Object { cmd /c "taskkill /PID $($_.ProcessId) /T /F >nul 2>&1" }
}
function Invoke-Edge([string[]]$argList, [string]$stdout) {
  if ($stdout) { $p = Start-Process -FilePath $edge -ArgumentList $argList -PassThru -RedirectStandardOutput $stdout -WindowStyle Hidden }
  else { $p = Start-Process -FilePath $edge -ArgumentList $argList -PassThru -WindowStyle Hidden }
  $p | Wait-Process -Timeout 60 -ErrorAction SilentlyContinue
  if (-not $p.HasExited) { cmd /c "taskkill /PID $($p.Id) /T /F >nul 2>&1" }
  Stop-Ours
}
function Parse([string]$shot) {
  $parts = $shot.Split('+'); $head = $parts[0]; $q = @()
  $id = $head; if ($head -match '@') { $id = $head.Split('@')[0]; $q += 'pick=' + $head.Split('@')[1] }
  if ($parts.Count -gt 1) { $q += $parts[1..($parts.Count - 1)] }
  $query = if ($q.Count) { '?' + ($q -join '&') } else { '' }
  @{ id = $id; query = $query; name = ($shot -replace '[@+=]', '-') }
}
$common = @('--headless', '--disable-gpu', '--hide-scrollbars', '--no-first-run', '--force-device-scale-factor=1', '--allow-file-access-from-files', "--user-data-dir=$edgeProfile")
if ($Budget -gt 0) { $common += "--virtual-time-budget=$Budget" }
if ($DumpDom) {
  $dom = Join-Path $out $DomOut
  Remove-Item $dom -ErrorAction SilentlyContinue
  Invoke-Edge ($common + @('--virtual-time-budget=5000', '--dump-dom', "$pageUrl$DomQuery")) $dom
  Write-Output ("dom: {0} bytes" -f (Get-Item $dom).Length)
  exit 0
}
foreach ($shot in $Shots) {
  $s = Parse $shot
  $png = Join-Path $out "$($s.name).png"
  $size = '1280,720'
  for ($try = 1; $try -le 2; $try++) {
    Remove-Item $png -ErrorAction SilentlyContinue
    Invoke-Edge ($common + @("--window-size=$size", "--screenshot=$png", "$pageUrl$($s.query)#$($s.id)")) $null
    if (Test-Path $png) {
      $img = [System.Drawing.Image]::FromFile($png); $w = $img.Width; $h = $img.Height; $img.Dispose()
      if ($w -eq 1280 -and $h -eq 720) { Write-Output "ok $($s.name) ${w}x${h}"; break }
      Write-Output "size $($s.name) ${w}x${h}"
      $size = "{0},{1}" -f (1280 + (1280 - $w)), (720 + (720 - $h))
    } else { Write-Output "missing $($s.name) (try $try)" }
  }
}
$left = @(Get-CimInstance Win32_Process -Filter "Name='msedge.exe'" | Where-Object { $_.CommandLine -like "*$edgeProfile*" }).Count
Write-Output "our edge left: $left"
