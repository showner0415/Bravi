param([string]$SheetPath = '', [string]$Label = '', [double]$Ppu = 0, [string]$J = '', [string]$R = '', [switch]$Calib)
# Plan 024: parts sheet K1, K2's, K3' at per-part places (022 calib.ps1 Sheet). K2 starts at the edge of each part's region (outside the part).
# -J "torso=x,y;legs=x,y;arm=x,y;head=x,y" (joints, px)  -R "torso=x0,x1;legs=x0,x1;arm=x0,x1;head=x0,x1" (region x bounds, px)
. (Join-Path $PSScriptRoot 'paths.ps1')
$s = $BraviWork
$gen = Join-Path $BraviRepo 'docs\style\generated'
. (Join-Path $PSScriptRoot 'kmeasure.ps1')
$cut = "$s\024\cut"; New-Item -ItemType Directory -Force $cut | Out-Null
function CutOf($src, $name) { $dst = "$cut\$name.png"; if (-not (Test-Path $dst)) { & (Join-Path $PSScriptRoot 'measure.ps1') -Src $src -Cut $dst | Out-Null }; $dst }
function ParseMap([string]$t) { $m = @{}; foreach ($e in $t.Split(';')) { $kv = $e.Split('='); $m[$kv[0]] = @($kv[1].Split(',') | ForEach-Object { [double]$_ }) }; $m }
function Y([double[]]$j, [double]$ppu, [double]$yu) { [int][math]::Round($j[1] + $yu * $ppu) }
function Rect([double[]]$j, [double]$ppu, [double]$x0, [double]$y0, [double]$x1, [double]$y1) { "{0},{1},{2},{3}" -f [int][math]::Round($j[0] + $x0 * $ppu), [int][math]::Round($j[1] + $y0 * $ppu), [int][math]::Round($j[0] + $x1 * $ppu), [int][math]::Round($j[1] + $y1 * $ppu) }
function Sheet($label, $path, $Jm, $Rm, $ppu) {
  $pts = @()
  foreach ($e in @(@('torso', -150), @('torso', -40), @('arm', 50), @('legs', 30), @('legs', 110), @('head', -20))) {
    $y = Y $Jm[$e[0]] $ppu $e[1]; $r = $Rm[$e[0]]
    $pts += "{0},{1},1" -f $y, [int]$r[0]; $pts += "{0},{1},-1" -f $y, [int]$r[1]
  }
  $r3 = @((Rect $Jm.torso $ppu -50 -180 65 -20), (Rect $Jm.legs $ppu -55 5 55 60), (Rect $Jm.arm $ppu -15 10 15 90)) -join ';'
  "== $label"; [KM]::K1($path, "0,0,4000,4000", $true); [KM]::K2($path, ($pts -join ';'), $ppu); [KM]::K3P($path, $r3, 24); "K5 density {0:F4}" -f [KM]::K5($path, '')
}
if ($Calib) {
  $svg = CutOf "$gen\in\022-in-parts.png" 'mix-parts'
  Sheet 'mix SVG parts' $svg (ParseMap 'torso=180,800;legs=444,608;arm=648,620;head=132,394') (ParseMap 'torso=100,260;legs=376,512;arm=620,676;head=60,204') 0.96
  Sheet '021 G2' "$gen\cut\021-G2-bartolo-parts.png" (ParseMap 'torso=211,910;legs=562,628;arm=840,651;head=157,392') (ParseMap 'torso=95,330;legs=455,670;arm=790,890;head=45,270') (282 / 200)
  return
}
Sheet $Label $SheetPath (ParseMap $J) (ParseMap $R) $Ppu
