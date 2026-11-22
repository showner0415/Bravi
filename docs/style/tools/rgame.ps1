param([string]$Dir, [string]$Sample = '', [string]$SampleTag = '')
# 계획 030 결정 270: 게임 렌더의 실루엣(tests/run_opponent_shots.ps1 -Sil, 28장)으로 R1·R2·R4를 낸다. 장의 이름과 쌍은 r026.ps1과 같다.
# -Sample <견본 실루엣 폴더> -SampleTag <tag>: 같은 장의 칼 팔(파랑) IoU를 낸다(S10, 게임이 견본과 같은 꼴인가).
$ErrorActionPreference = 'Stop'
$sil = Join-Path $PSScriptRoot 'sil026.ps1'
$all = @('thrust', 'cutl', 'cutr', 'big')
function F([string]$n) { Join-Path $Dir "sil-$n.png" }
$noarm = & $sil -Count (F 'idle-mid-noarm')
$noRed = [double](($noarm -split ',')[3])
"noarm,red $noRed"
# R1: 쌍 여섯(공격끼리)과 넷(공격 대 대기), 진행 둘 × 간격 둘
foreach ($p in '25', '60') { foreach ($d in 'mid', 'far') {
  $pairs = @()
  for ($i = 0; $i -lt 4; $i++) { for ($j = $i + 1; $j -lt 4; $j++) { $pairs += "$(F "$($all[$i])-tell$p-$d"),$(F "$($all[$j])-tell$p-$d")" }; $pairs += "$(F "$($all[$i])-tell$p-$d"),$(F "idle-$d")" }
  & $sil -Iou ($pairs -join ';') | ForEach-Object { $q = $_ -split ','; "R1,0.$p,$d,$($q[1] -replace '^sil-',''),$($q[2] -replace '^sil-',''),$($q[3])" }
} }
# R2: 1 - 빨강 ÷ 팔 없는 장의 빨강(교전)
$r2 = @(); foreach ($a in $all) { $r2 += (F "$a-tell25-mid"), (F "$a-tell60-mid"), (F "$a-recover-mid") }; $r2 += (F 'idle-mid'), (F 'complacent-mid')
& $sil -Count ($r2 -join ';') | ForEach-Object { $q = $_ -split ','; "R2,$($q[1] -replace '^sil-',''),{0:0.000}" -f (1 - [double]$q[3] / $noRed) }
# R4: 상태 글자의 잉크 상자 x 497~783 · y 62~142 안의 파랑(교전·밀착의 예비 동작 25%)
$r4 = @(); foreach ($a in $all) { $r4 += "$(F "$a-tell25-mid"),497,62,783,142", "$(F "$a-tell25-close"),497,62,783,142" }
& $sil -Box ($r4 -join ';') | ForEach-Object { $q = $_ -split ','; "R4,$($q[1] -replace '^sil-',''),$($q[6])" }
if ($Sample) {
  # S10: 견본 장의 이름(r026.ps1의 File)과 짝지어 칼 팔 IoU
  $map = @{}
  foreach ($a in $all) {
    foreach ($p in '0.25', '0.6') { foreach ($d in 'mid', 'far') { $map["$a-tell$($p.Substring(2).PadRight(2, '0'))-$d"] = "atk-$a-ph-tell-p-$p-dist-$d" } }
    $map["$a-recover-mid"] = "atk-$a-ph-recover-dist-mid"; $map["$a-tell25-close"] = "atk-$a-ph-tell-p-0.25-dist-close"
  }
  $map['idle-mid'] = 'atk-big-ph-idle-dist-mid'; $map['idle-far'] = 'atk-big-ph-idle-dist-far'; $map['complacent-mid'] = 'atk-big-ph-complacent-dist-mid'
  $pairs = @(); foreach ($k in $map.Keys) { $pairs += "$(F $k),$(Join-Path $Sample "sil-col-rot-curve-hold-tag-$SampleTag-$($map[$k]).png")" }
  & $sil -Iou ($pairs -join ';') | ForEach-Object { $q = $_ -split ','; "S10,$($q[1] -replace '^sil-',''),$($q[3])" }
}
