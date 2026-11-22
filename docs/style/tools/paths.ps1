# 계획 028 결정 250: 판정 도구의 경로를 한 곳에서 정한다. 도구는 . (Join-Path $PSScriptRoot 'paths.ps1')로 읽는다.
# 작업 폴더는 저장소 밖이어야 한다(바이블 13.5). 저장소 안이면 만들기 전에 멈춘다.
$BraviRepo = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\..\..')).TrimEnd('\')
$w = $env:BRAVI_STYLE_WORK
if (-not $w) { $w = Join-Path $env:TEMP 'bravi-style' }
$BraviWork = [IO.Path]::GetFullPath($w).TrimEnd('\')
if ($BraviWork -ieq $BraviRepo -or $BraviWork.StartsWith($BraviRepo + '\', [StringComparison]::OrdinalIgnoreCase)) { throw "BRAVI_STYLE_WORK must be outside the repository: $BraviWork" }
if (-not (Test-Path $BraviWork)) { New-Item -ItemType Directory -Force -Path $BraviWork | Out-Null }
$BraviSamplesUrl = 'file:///' + ($BraviRepo -replace '\\', '/') + '/docs/style/samples/'
