param([string]$SheetPath, [string]$Label = '026 arms', [double]$Ppu, [string]$Sleeves)
# 계획 026 판정 A-2: calib024의 Sheet()를 팔 파츠로 바꾼 것. 파츠는 시트 위에 세로로 서 있다(결정 237).
# -Sleeves "x0,y0,x1,y1;..." 파츠마다 소매만의 상자(소매 끝·주먹·칼을 뺀다, 손질본의 화소).
# K2: 소매 높이의 1/3·2/3 가로줄 둘, 양옆에서 들어가는 점 넷(시작 x는 상자 밖 4화소). K3': 소매 상자의 가로 가운데 50% · 세로 20~80%.
. (Join-Path $PSScriptRoot 'paths.ps1')
$s = $BraviWork
. (Join-Path $PSScriptRoot 'kmeasure.ps1')
$pts = @(); $r3 = @(); $k1 = @()
foreach ($b in ($Sleeves.Split(';') | Where-Object { $_ })) {
  $v = @($b.Split(',') | ForEach-Object { [int]$_ }); $x0 = $v[0]; $y0 = $v[1]; $x1 = $v[2]; $y1 = $v[3]; $h = $y1 - $y0; $w = $x1 - $x0
  foreach ($f in (1.0 / 3), (2.0 / 3)) { $y = [int][math]::Round($y0 + $h * $f); $pts += "{0},{1},1" -f $y, ($x0 - 4); $pts += "{0},{1},-1" -f $y, ($x1 + 4) }
  $r3 += "{0},{1},{2},{3}" -f [int]($x0 + $w * 0.25), [int]($y0 + $h * 0.2), [int]($x0 + $w * 0.75), [int]($y0 + $h * 0.8)
  $k1 += "{0},{1},{2},{3}" -f ($x0 - 8), ($y0 - 8), ($x1 + 8), ($y1 + 8)
}
"== $Label (ppu $Ppu)"
"K3' boxes $($r3 -join ';')"
[KM]::K1($SheetPath, ($k1 -join ';'), $true)
[KM]::K2($SheetPath, ($pts -join ';'), $Ppu)
[KM]::K3P($SheetPath, ($r3 -join ';'), 24)
