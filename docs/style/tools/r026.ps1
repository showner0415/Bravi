param([string]$Col = 'rot', [switch]$Bake, [string[]]$Atks = @('thrust', 'cutl', 'cutr', 'big'), [string]$Curve = 'hold', [string]$Tag = '')
# 계획 026 작업 4: 실루엣을 굽고 R1(칼 팔의 겹침)·R2(머리의 가림)·R4(상태 글자 상자의 파랑)를 낸다.
# -Tag는 고친 차례를 파일 이름에 붙여 앞의 굽기를 덮지 않게 한다.
$ErrorActionPreference = 'Stop'
$tools = Split-Path -Parent $MyInvocation.MyCommand.Path
. (Join-Path $PSScriptRoot 'paths.ps1')
$scratch = $BraviWork
$dir = Join-Path $scratch '026'
$all = @('thrust', 'cutl', 'cutr', 'big')
$base = "sil+col=$Col+curve=$Curve"
if ($Tag) { $base += "+tag=$Tag" }
function Shot([string]$rest) { "$base+$rest" }
function File([string]$shot) { Join-Path $dir (($shot -replace '[@+=]', '-') + '.png') }
$shots = @()
foreach ($a in $Atks) {
  foreach ($p in '0.25', '0.6') { foreach ($d in 'mid', 'far') { $shots += Shot "atk=$a+ph=tell+p=$p+dist=$d" } }
  $shots += Shot "atk=$a+ph=recover+dist=mid"
  $shots += Shot "atk=$a+ph=tell+p=0.25+dist=close"
}
$common = @((Shot 'atk=big+ph=idle+dist=mid'), (Shot 'atk=big+ph=idle+dist=far'), (Shot 'atk=big+ph=complacent+dist=mid'), (Shot 'atk=big+ph=idle+dist=mid+noarm=1'))
$need = $common | Where-Object { -not (Test-Path (File $_)) }
if ($Bake) {
  $todo = @($shots) + @($need)
  & (Join-Path $tools 'bake025.ps1') -Page 026-pose-motion.html -OutDir 026 -Budget 5000 -Shots $todo | Where-Object { $_ -notmatch '^ok ' }
}
$sil = Join-Path $tools 'sil026.ps1'
$F = @{}
foreach ($a in $all) {
  foreach ($p in '0.25', '0.6') { foreach ($d in 'mid', 'far') { $F["$a|$p|$d"] = File (Shot "atk=$a+ph=tell+p=$p+dist=$d") } }
  $F["$a|rec"] = File (Shot "atk=$a+ph=recover+dist=mid"); $F["$a|close"] = File (Shot "atk=$a+ph=tell+p=0.25+dist=close")
}
$F['idle|mid'] = File $common[0]; $F['idle|far'] = File $common[1]; $F['comp'] = File $common[2]; $F['noarm'] = File $common[3]
# 재기 전의 확인: noarm은 빨강 > 0 · 파랑 = 0, 공격 장마다 파랑 > 0 · 빨강 > 0
$pre = & $sil -Count (@($F['noarm']) + ($all | ForEach-Object { $F["$_|0.6|mid"] }) -join ';')
$pre | ForEach-Object { "pre,$_" }
$noRed = [double](($pre[0] -split ',')[3])
# R1: 쌍 여섯(공격끼리)과 넷(공격 대 대기), 진행 둘 × 간격 둘
foreach ($p in '0.25', '0.6') { foreach ($d in 'mid', 'far') {
  $pairs = @()
  for ($i = 0; $i -lt 4; $i++) { for ($j = $i + 1; $j -lt 4; $j++) { $pairs += "$($F["$($all[$i])|$p|$d"]),$($F["$($all[$j])|$p|$d"])" } ; $pairs += "$($F["$($all[$i])|$p|$d"]),$($F["idle|$d"])" }
  & $sil -Iou ($pairs -join ';') | ForEach-Object { $q = $_ -split ','; "R1,$p,$d,$($q[1] -replace "^sil-col-$Col-curve-$Curve-(tag-[^-]+-)?",''),$($q[2] -replace "^sil-col-$Col-curve-$Curve-(tag-[^-]+-)?",''),$($q[3])" }
} }
# R2: 1 - 빨강 ÷ noarm의 빨강(교전)
$r2 = @(); foreach ($a in $all) { $r2 += $F["$a|0.25|mid"], $F["$a|0.6|mid"], $F["$a|rec"] }; $r2 += $F['idle|mid'], $F['comp']
& $sil -Count ($r2 -join ';') | ForEach-Object { $q = $_ -split ','; "R2,$($q[1] -replace "^sil-col-$Col-curve-$Curve-(tag-[^-]+-)?",''),{0:0.000}" -f (1 - [double]$q[3] / $noRed) }
# R4: 상태 글자의 잉크 상자 x 497~783 · y 62~142 안의 파랑(교전·밀착의 예비 동작 25%)
$r4 = @(); foreach ($a in $all) { $r4 += "$($F["$a|0.25|mid"]),497,62,783,142", "$($F["$a|close"]),497,62,783,142" }
& $sil -Box ($r4 -join ';') | ForEach-Object { $q = $_ -split ','; "R4,$($q[1] -replace "^sil-col-$Col-curve-$Curve-(tag-[^-]+-)?",''),$($q[6])" }
