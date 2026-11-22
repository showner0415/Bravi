param([string]$Target = 'docs/STYLE_BIBLE.md', [string[]]$Sources = @(), [string[]]$Only = @())
# 계획 027 결정 244: 바이블(또는 견본)이 옮긴 값이 원문과 같은지 본다. V마다 첫 줄에 검사한 개수를 낸다(0이면 통과가 아니다).
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'paths.ps1')
$root = $BraviRepo
$utf8 = New-Object System.Text.UTF8Encoding $false
function P([string]$rel) { if ([IO.Path]::IsPathRooted($rel)) { $rel } else { Join-Path $root ($rel -replace '/', '\') } }
function ReadText([string]$rel) { [IO.File]::ReadAllText((P $rel), $utf8) }
function CountOf([string]$hay, [string]$needle) { $n = 0; $i = 0; while (($i = $hay.IndexOf($needle, $i, [StringComparison]::Ordinal)) -ge 0) { $n++; $i += [Math]::Max(1, $needle.Length) }; $n }
function Want([string]$v) { (-not $Only) -or ($Only -contains $v) }

if (-not (Test-Path (P $Target))) { "target missing: $Target"; exit 1 }
if (-not $Sources) {
  $Sources = @('docs/style/STYLE_SPEC.md', 'docs/style/basis/README.md', 'docs/style/GENERATION.md', 'docs/style/REFERENCES.md', 'docs/DECISIONS.md', 'CLAUDE.md', 'docs/style/samples/026-pose-motion.html')
  $Sources += @(Get-ChildItem (P 'docs/plans') -Filter '02*.md' | Where-Object { $_.Name -match '^02[0-7]-' } | ForEach-Object { $_.FullName })
}
$src = ($Sources | ForEach-Object { ReadText $_ }) -join "`n"
$text = ReadText $Target
$lines = $text -split "`n" | ForEach-Object { $_.TrimEnd("`r") }
# 줄마다 바로 위의 ## 또는 ### 머리
$sec = New-Object string[] $lines.Count; $cur = '(머리)'
for ($i = 0; $i -lt $lines.Count; $i++) { if ($lines[$i] -match '^#{2,3} ') { $cur = $lines[$i] }; $sec[$i] = $cur }
$heads = '^(Task:|Image:|Subject:|Pose and layout:|Composition:|Change:|Style \(|Colors:|Background:)'

if (Want 'V1') {
  $cols = @([regex]::Matches($text, '#[0-9A-Fa-f]{6}') | ForEach-Object { $_.Value.ToUpper() } | Sort-Object -Unique)
  $srcU = $src.ToUpper(); $miss = @($cols | Where-Object { -not $srcU.Contains($_) })
  "V1 checked $($cols.Count) colors"; $miss | ForEach-Object { "V1 missing $_" }; "V1 missing-count $($miss.Count)"
}
if (Want 'V2') {
  $n = 0; $out = 0; $in = 0
  for ($i = 0; $i -lt $lines.Count; $i++) {
    $l = $lines[$i]
    if ($l -notmatch '^\s*\|' -or $l -match '^\s*\|[\s:|-]+\|\s*$') { continue }
    $n++; $t = $l.Trim()
    if ($src.Contains($t)) { continue }
    $ex = $sec[$i] -match '^## (2|14|16)\. ' -or $sec[$i] -match '^### 13\.(3|6) '
    if ($ex) { $in++ } else { $out++; "V2 missing line $($i + 1) [$($sec[$i])]: $($t.Substring(0, [Math]::Min(70, $t.Length)))" }
  }
  "V2 checked $n table-lines"; "V2 missing-outside $out"; "V2 missing-inside(exempt) $in"
}
if (Want 'V3') {
  $vals = @(
    @('바깥 5.2·안 2.9·눈썹 7.0', 'docs/DECISIONS.md'), @('가운데 × k 5.0~5.6', 'docs/style/STYLE_SPEC.md'), @('3.6~7.8', 'docs/style/STYLE_SPEC.md'),
    @('머리가 몸의 약 0.28', 'docs/style/STYLE_SPEC.md'), @('x 433~847, y 62~683', 'docs/style/STYLE_SPEC.md'), @('S ≥ 55%이면서 V ≥ 85%', 'docs/style/STYLE_SPEC.md'),
    @('칠 Y ≥ 0.42', 'docs/style/STYLE_SPEC.md'), @('교전 꼭대기 ≥ 142(모자 ≤ 53)', 'docs/style/STYLE_SPEC.md'),
    @('목 밑동은 목 위로 12, 팔 윗끝은 어깨 위로 14', 'docs/style/samples/026-pose-motion.html'), @('허용 차 28', 'docs/style/basis/README.md'),
    @('±30, R − B ≥ 5', 'docs/plans/023-style-transfer-new-drawing.md'), @('가운데 값의 0.6~1.6배를 벗어난 점이 3개 이하', 'docs/plans/023-style-transfer-new-drawing.md'),
    @('가장 작은 값 ≤ 0.025', 'docs/plans/023-style-transfer-new-drawing.md'), @('H11 ≤ 0.01', 'docs/style/GENERATION.md'),
    @('L 평균 ≤ 0.20, 95번째 ≤ 0.30', 'docs/plans/023-style-transfer-new-drawing.md'), @('`borderSpreadR` ≤ 6', 'docs/plans/026-pose-and-motion.md'),
    @('024 팔 폭의 0.85~1.15배', 'docs/plans/026-pose-and-motion.md'), @('R1 칼 팔의 겹침 ≤ 0.30, R2 머리의 가림 ≤ 0.10', 'docs/DECISIONS.md'),
    @('model_reasoning_effort=high', 'docs/style/GENERATION.md'), @('AA004752', 'docs/style/GENERATION.md'),
    @('swing = min(0.2 × 예비 동작, 패리 창 − 0.03)', 'docs/style/STYLE_SPEC.md'), @('목~골반이 원본 330화소 이상', 'docs/style/STYLE_SPEC.md'),
    @('`Legs` / `Torso` > `Head` > `Hat` / `Torso` > `Arm` > `Hand` > `Sword`', 'docs/DECISIONS.md'))
  $ok = 0; $k = 0
  foreach ($v in $vals) { $k++; $a = CountOf $text $v[0]; $b = CountOf (ReadText $v[1]) $v[0]; if ($a -ge 1 -and $b -ge 1) { $ok++ }; "V3 $k target $a source $b" }
  "V3 checked $($vals.Count) values"; "V3 found $ok/$($vals.Count)"
}
if (Want 'V4') {
  $spec = (ReadText 'docs/style/STYLE_SPEC.md') -split "`n" | ForEach-Object { $_.TrimEnd("`r") }
  $names = @($spec | Where-Object { $_ -match '^## ' } | ForEach-Object { $h = $_.Substring(3); if ($h.EndsWith(')') -and $h.IndexOf(' (') -ge 0) { $h = $h.Substring(0, $h.IndexOf(' (')) }; $h })
  $rows = 0; $files = 0; $nameN = 0; $bad = 0; $noName = 0; $noFile = 0
  for ($i = 0; $i -lt $lines.Count; $i++) {
    if ($sec[$i] -notmatch '^### 13\.3 ' -or $lines[$i] -notmatch '^\s*\|' -or $lines[$i] -match '^\s*\|[\s:|-]+\|\s*$') { continue }
    $c = $lines[$i].Trim().Trim('|').Split('|') | ForEach-Object { $_.Trim() }
    if ($c[0] -eq '그림') { continue }
    $rows++
    $order = @([regex]::Matches($c[3], '`([^`]+)`') | ForEach-Object { $_.Groups[1].Value })
    foreach ($f in [regex]::Matches($c[2], '`([^`]+)`')) {
      $files++; $fp = $f.Groups[1].Value
      if (-not (Test-Path (P $fp))) { $noFile++; "V4 no file $fp"; continue }
      $hs = @((ReadText $fp) -split "`n" | ForEach-Object { $m = [regex]::Match($_, $heads); if ($m.Success) { $m.Value } })
      if (($hs -join '|') -ne ($order -join '|')) { $bad++; "V4 order mismatch line $($i + 1) $fp : file [$($hs -join ' > ')] table [$($order -join ' > ')]" }
    }
    foreach ($nm in ($c[4] -split ' / ')) { $nm = $nm.Trim(); $nameN++; if ($names -notcontains $nm) { $noName++; "V4 no block name line $($i + 1): $nm" } }
  }
  "V4 checked rows $rows files $files names $nameN"; "V4 order-mismatch $bad no-name $noName no-file $noFile"
}
if (Want 'V5') {
  $h = 0; $f = 0
  for ($i = 0; $i -lt $lines.Count; $i++) { if ($lines[$i] -match $heads) { $h++; "V5 head line $($i + 1)" }; if ($lines[$i] -match '^\s*```') { $f++; "V5 fence line $($i + 1)" } }
  "V5 checked $($lines.Count) lines"; "V5 heads $h fences $f"
}
if (Want 'V6') {
  $n = 0; $outN = 0
  for ($i = 0; $i -lt $lines.Count; $i++) { if ($lines[$i] -match '피자|Potion') { $n++; if ($sec[$i] -notmatch '^## 3\. ') { $outN++; "V6 outside line $($i + 1) [$($sec[$i])]" } } }
  "V6 checked $n lines"; "V6 outside-3 $outN"
}
if (Want 'V7') {
  $paths = @(); $skip = 0
  foreach ($m in [regex]::Matches($text, '`([^`]+)`')) { $t = $m.Groups[1].Value; if ($t -match '^(docs/|CLAUDE\.md)') { $paths += $t } }
  foreach ($m in [regex]::Matches($text, '\]\(([^)]+)\)')) { $paths += 'docs/' + $m.Groups[1].Value }
  $n = 0; $miss = 0
  foreach ($p in $paths) {
    if ($p -match '[<>{}*…]') { $skip++; continue }
    $q = ($p -split '[ #]')[0]; $n++
    if (-not (Test-Path (P $q))) { $miss++; "V7 missing $q" }
  }
  "V7 checked $n paths (skipped placeholders $skip)"; "V7 missing-count $miss"
}
if (Want 'V8') {
  $a = @($lines | Where-Object { $_ -match '^## (\d+)\. ' } | ForEach-Object { [int]([regex]::Match($_, '^## (\d+)\. ').Groups[1].Value) })
  $b = @($lines | Where-Object { $_ -match '^### 13\.(\d) ' } | ForEach-Object { [int]([regex]::Match($_, '^### 13\.(\d) ').Groups[1].Value) })
  $s5 = (($lines | Select-Object -Index (0..($lines.Count - 1) | Where-Object { $sec[$_] -match '^## 5\. ' })) -join "`n")
  $v9 = CountOf $s5 '목 밑동은 목 위로 12, 팔 윗끝은 어깨 위로 14'
  "V8 checked sections $($a.Count) sub13 $($b.Count) value9-in-5 $v9"
  "V8 sections [$($a -join ',')] ok $(($a -join ',') -eq ((1..16) -join ','))"; "V8 sub13 [$($b -join ',')] ok $(($b -join ',') -eq ((1..8) -join ','))"
}
if (Want 'V9') {
  $norm = { param($s) ($s -replace '\s+', ' ').Trim() }
  $srcN = & $norm (($src -replace '`', '') -replace '\*\*', '')
  $els = [regex]::Matches($text, '<(\w+)[^>]*\bdata-from-bible\b[^>]*>(.*?)</\1>', [Text.RegularExpressions.RegexOptions]::Singleline)
  $miss = 0
  foreach ($e in $els) { $g = & $norm ([System.Net.WebUtility]::HtmlDecode(($e.Groups[2].Value -replace '<[^>]+>', ''))); if (-not $srcN.Contains($g)) { $miss++; "V9 missing: $g" } }
  "V9 checked $($els.Count) elements"; "V9 missing-count $miss"
}
