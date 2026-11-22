param([string]$G, [int]$Try = 1, [string]$Name, [string[]]$Images, [string]$Sandbox = 'read-only', [int]$TimeoutSec = 900, [string]$Plan = '021', [string[]]$Phrases = @(), [switch]$DryRun)
# 계획 021 결정 184: 저장소 밖 빈 작업 폴더, 읽기 전용, 이 호출만의 끄기, 전후 대조, 세션 기록. 이름으로 끄지 않는다.
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'paths.ps1')
$repo = $BraviRepo
$scratch = $BraviWork
$codexHome = Join-Path $env:USERPROFILE '.codex'
$work = Join-Path $scratch "codex\$G-$Name-$Try"
if (Test-Path $work) { throw "work dir exists: $work" }
New-Item -ItemType Directory -Path $work | Out-Null
$promptSrc = Join-Path $repo "docs\style\prompts\$Plan-$G-$Name.txt"
(Get-Content -Raw $promptSrc).Replace('{WORKDIR}', $work) | Set-Content -NoNewline -Encoding ascii (Join-Path $work 'prompt.txt')
$i = 0; $imgArgs = @()
foreach ($img in $Images) { $i++; $dst = Join-Path $work "in-$i.png"; Copy-Item $img $dst; $imgArgs += "--image=$dst" }

function Snap {
  $o = [ordered]@{}
  $o.git = (& git -C $repo status --short) -join "`n"
  $o.diff = (& git -C $repo diff --stat) -join "`n"
  $o.cfg = (Get-FileHash (Join-Path $codexHome 'config.toml')).Hash
  $o.work = ((Get-ChildItem $work -Name) | Sort-Object) -join ','
  return $o
}
$t0 = Get-Date
$pre = Snap
$preImgs = @(Get-ChildItem (Join-Path $codexHome 'generated_images') -Recurse -File -ErrorAction SilentlyContinue | Where-Object { $_.LastWriteTime -lt $t0 }).Count

$plugins = 'codex-app-tools@openai-bundled', 'browser@openai-bundled', 'unified-computer-use@openai-bundled', 'visualize@openai-bundled', 'computer-use@openai-bundled', 'documents@openai-primary-runtime', 'pdf@openai-primary-runtime', 'spreadsheets@openai-primary-runtime', 'presentations@openai-primary-runtime', 'template-creator@openai-primary-runtime'
$argList = @('exec', '-', '--skip-git-repo-check', '-C', $work, '-s', $Sandbox, '--json', '-o', (Join-Path $work 'last.txt'),
  '-m', 'gpt-6.2-sol', '-c', 'model_reasoning_effort=high',
  '-c', 'notify=[]', '-c', 'mcp_servers.node_repl.enabled=false',
  '--disable', 'plugins', '--disable', 'apps', '--disable', 'computer_use', '--disable', 'browser_use', '--disable', 'browser_use_external')
foreach ($p in $plugins) { $argList += @('-c', "plugins.$p.enabled=false") }
$argList += $imgArgs
($argList -join ' ') | Set-Content -Encoding utf8 (Join-Path $work 'cmd.txt')
if ($DryRun) { Get-Content (Join-Path $work 'cmd.txt'); exit 0 }

$cmd = Join-Path $env:APPDATA 'npm\codex.cmd'
$p = Start-Process -FilePath $cmd -ArgumentList $argList -WorkingDirectory $work -RedirectStandardInput (Join-Path $work 'prompt.txt') -RedirectStandardOutput (Join-Path $work 'events.jsonl') -RedirectStandardError (Join-Path $work 'err.txt') -NoNewWindow -PassThru
$p | Wait-Process -Timeout $TimeoutSec -ErrorAction SilentlyContinue
$timedOut = $false
if (-not $p.HasExited) { $timedOut = $true; taskkill /PID $p.Id /T /F 2>$null | Out-Null }
$t1 = Get-Date
$post = Snap

$r = [ordered]@{}
$r.G = "$G-$Try"; $r.seconds = [int]($t1 - $t0).TotalSeconds; $r.timedOut = $timedOut; $r.exit = if ($p.HasExited) { $p.ExitCode } else { 'killed' }
$r.git_same = ($pre.git -eq $post.git) -and ($pre.diff -eq $post.diff)
$r.cfg_same = ($pre.cfg -eq $post.cfg); $r.cfg = $post.cfg
$r.work_files = $post.work
$r.old_imgs_same = ($preImgs -eq @(Get-ChildItem (Join-Path $codexHome 'generated_images') -Recurse -File | Where-Object { $_.LastWriteTime -lt $t0 }).Count)
$ev = Join-Path $work 'events.jsonl'
$thread = $null
if (Test-Path $ev) {
  $m = Select-String -Path $ev -Pattern '"thread_id":"([^"]+)"' | Select-Object -First 1
  if ($m) { $thread = $m.Matches[0].Groups[1].Value }
  $r.usage = (Select-String -Path $ev -Pattern '"usage":\{[^}]*\}' -AllMatches | ForEach-Object { $_.Matches.Value }) -join ' | '
  $r.event_types = ((Select-String -Path $ev -Pattern '"type":"([a-z_.]+)"' -AllMatches | ForEach-Object { $_.Matches | ForEach-Object { $_.Groups[1].Value } }) | Group-Object | ForEach-Object { "$($_.Name)x$($_.Count)" }) -join ','
}
$r.thread = $thread
$r.err_tail = ((Get-Content (Join-Path $work 'err.txt') -ErrorAction SilentlyContinue | Select-Object -Last 6) -join ' / ')
$r.last = (Get-Content (Join-Path $work 'last.txt') -Raw -ErrorAction SilentlyContinue)
$found = @()
if ($thread) {
  $dir = Join-Path $codexHome "generated_images\$thread"
  if (Test-Path $dir) { $found = @(Get-ChildItem $dir -File -Filter *.png) }
  $roll = Get-ChildItem (Join-Path $codexHome 'sessions') -Recurse -File -Filter "rollout-*-$thread.jsonl" | Select-Object -First 1
  if ($roll) {
    $r.rollout = $roll.FullName
    $tc = Select-String -Path $roll.FullName -Pattern '"type":"turn_context"' | Select-Object -First 1
    if ($tc) {
      $r.model = ([regex]::Match($tc.Line, '"model":"([^"]+)"')).Groups[1].Value
      $r.effort = ([regex]::Match($tc.Line, '"effort":"([^"]+)"')).Groups[1].Value
      $r.sandbox = ([regex]::Match($tc.Line, '"sandbox_policy":\{"type":"([^"]+)"')).Groups[1].Value
    }
    # 노출된 도구: 도구 정의의 "name" 값만 본다(프롬프트 글에 걸리지 않게. 검토자 제안)
    $names = Select-String -Path $roll.FullName -Pattern '"name":"([^"]+)"' -AllMatches | ForEach-Object { $_.Matches | ForEach-Object { $_.Groups[1].Value } } | Sort-Object -Unique
    $r.names_seen = $names -join ','
    $r.exposed_bad = ($names | Where-Object { $_ -match '(cua|browser|codex_apps|computer)' -or $_ -eq 'js' }) -join ','
    # 부른 도구: 호출 항목의 줄에서만 센다
    $callLines = Select-String -Path $roll.FullName -Pattern '"type":"(function_call|custom_tool_call)"'
    $r.calls = ($callLines | ForEach-Object { ([regex]::Match($_.Line, '"name":"([^"]+)"')).Groups[1].Value }) -join ','
    $r.inner_calls = (($callLines | ForEach-Object { [regex]::Matches($_.Line, 'tools\.([a-z_]+)\(') | ForEach-Object { $_.Groups[1].Value } }) | Sort-Object -Unique) -join ','
    $r.ref_paths = (Select-String -Path $roll.FullName -Pattern 'referenced_image_paths' -SimpleMatch | Measure-Object).Count
    $r.ref_paths_in_calls = (($callLines | Where-Object { $_.Line -match 'referenced_image_paths' }) | Measure-Object).Count
    $r.num_last = (($callLines | Where-Object { $_.Line -match 'num_last_images_to_include' }) | Measure-Object).Count
    $r.transparent = (($callLines | Where-Object { $_.Line -match 'transparent_background' }) | Measure-Object).Count
    $r.rate = ((Select-String -Path $roll.FullName -Pattern '"used_percent":[0-9.]+' -AllMatches | ForEach-Object { $_.Matches.Value }) | Select-Object -Last 4) -join ','
    $r.f11 = (($Phrases | ForEach-Object { $ph = $_; "{0}={1}" -f $ph, [bool]($callLines | Where-Object { $_.Line.Contains('image_gen__imagegen(') -and $_.Line.Contains($ph) }) }) -join ',')
    $r.token_total = ((Select-String -Path $roll.FullName -Pattern '"total_token_usage":\{[^}]*\}' -AllMatches | ForEach-Object { $_.Matches.Value }) | Select-Object -Last 1)
  }
}
$outDir = Join-Path $repo 'docs\style\generated'
New-Item -ItemType Directory -Force -Path $outDir | Out-Null
$k = 0; $copied = @()
foreach ($fi in $found) {
  $k++
  $suffix = if ($found.Count -gt 1) { "-$k" } else { '' }
  $dst = Join-Path $outDir "$Plan-$G-$Name$suffix.png"
  if ($Try -gt 1) { $dst = Join-Path $outDir "$Plan-$G-$Name-t$Try$suffix.png" }
  Copy-Item $fi.FullName $dst
  Add-Type -AssemblyName System.Drawing
  $im = [System.Drawing.Image]::FromFile($dst); $copied += ("{0} {1}x{2} {3}B" -f (Split-Path $dst -Leaf), $im.Width, $im.Height, (Get-Item $dst).Length); $im.Dispose()
}
$r.images = $copied -join ' ; '
$r.GetEnumerator() | ForEach-Object { "{0}: {1}" -f $_.Key, $_.Value } | Tee-Object -FilePath (Join-Path $work 'summary.txt')
