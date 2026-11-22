param([string]$Grow = '', [string]$Sheet = '', [string]$Out = '')
# 계획 028 작업 5: 기준 시트 basis/bartolo-parts.png에서 파츠 열 장을 잘라 assets/art/opponents/bartolo/에 둔다.
# 바탕은 measure.ps1로 지우고(허용 차 28), 화소를 늘리거나 줄이지 않는다(결정 251). 상자·관절·배율은 basis/README.md "손질 값".
# -Grow "head=0,0,0,2;feather=0,1,0,3": 파츠마다 왼·위·오른·아래로 넓힐 화소(가장자리에 불투명 화소가 걸릴 때. 작업 6의 4).
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'paths.ps1')
Add-Type -AssemblyName System.Drawing
if (-not ('CutParts' -as [type])) {
Add-Type -ReferencedAssemblies System.Drawing -TypeDefinition @'
using System; using System.Drawing; using System.Drawing.Imaging; using System.Runtime.InteropServices;
public static class CutParts {
  public static byte[] Load(Bitmap b, out int st) {
    var d = b.LockBits(new Rectangle(0, 0, b.Width, b.Height), ImageLockMode.ReadOnly, PixelFormat.Format32bppArgb);
    st = d.Stride; var a = new byte[st * b.Height]; Marshal.Copy(d.Scan0, a, 0, a.Length); b.UnlockBits(d); return a;
  }
  // 반환: 폭, 높이, 가장자리 불투명, RGB 다름, 경계 화소, 경계의 밝은 화소
  public static int[] Cut(string cutPath, string srcPath, int x0, int y0, int x1, int y1, string outPath) {
    var cb = new Bitmap(cutPath); var sb = new Bitmap(srcPath); int cst, sst;
    var c = Load(cb, out cst); var s = Load(sb, out sst); int W = cb.Width, H = cb.Height; cb.Dispose(); sb.Dispose();
    int w = x1 - x0 + 1, h = y1 - y0 + 1; var o = new Bitmap(w, h, PixelFormat.Format32bppArgb);
    var od = o.LockBits(new Rectangle(0, 0, w, h), ImageLockMode.WriteOnly, PixelFormat.Format32bppArgb); int ost = od.Stride; var a = new byte[ost * h];
    int edge = 0, diff = 0, border = 0, bright = 0;
    for (int y = 0; y < h; y++) for (int x = 0; x < w; x++) {
      int sx = x0 + x, sy = y0 + y; int oi = y * ost + x * 4;
      if (sx < 0 || sy < 0 || sx >= W || sy >= H) continue;
      int ci = sy * cst + sx * 4; a[oi] = c[ci]; a[oi + 1] = c[ci + 1]; a[oi + 2] = c[ci + 2]; a[oi + 3] = c[ci + 3];
      if (c[ci + 3] == 0) continue;
      if (x == 0 || y == 0 || x == w - 1 || y == h - 1) edge++;
      int si = sy * sst + sx * 4; if (c[ci] != s[si] || c[ci + 1] != s[si + 1] || c[ci + 2] != s[si + 2]) diff++;
    }
    for (int y = 0; y < h; y++) for (int x = 0; x < w; x++) {
      int oi = y * ost + x * 4; if (a[oi + 3] == 0) continue;
      bool nearT = false;
      int[] dx = { -1, 1, 0, 0 }, dy = { 0, 0, -1, 1 };
      for (int k = 0; k < 4; k++) { int nx = x + dx[k], ny = y + dy[k]; if (nx < 0 || ny < 0 || nx >= w || ny >= h || a[ny * ost + nx * 4 + 3] == 0) { nearT = true; break; } }
      if (!nearT) continue; border++;
      double Y = (0.2126 * a[oi + 2] + 0.7152 * a[oi + 1] + 0.0722 * a[oi]) / 255.0; if (Y >= 0.6) bright++;
    }
    Marshal.Copy(a, 0, od.Scan0, a.Length); o.UnlockBits(od); o.Save(outPath, ImageFormat.Png); o.Dispose();
    return new int[] { w, h, edge, diff, border, bright };
  }
  // 열 장을 한 색 바탕 위에 늘어놓는다(눈으로 테두리를 본다)
  public static void Board(string[] files, string bg, string outPath) {
    var col = ColorTranslator.FromHtml(bg); var b = new Bitmap(1600, 900, PixelFormat.Format32bppArgb);
    using (var g = Graphics.FromImage(b)) { g.Clear(col); int x = 20, y = 20, rowH = 0;
      foreach (var f in files) { using (var im = new Bitmap(f)) { if (x + im.Width > 1580) { x = 20; y += rowH + 20; rowH = 0; } g.DrawImage(im, x, y, im.Width, im.Height); x += im.Width + 20; rowH = Math.Max(rowH, im.Height); } } }
    b.Save(outPath, ImageFormat.Png); b.Dispose();
  }
}
'@
}
# 이름, 파일, 상자 x0,y0,x1,y1, 시트의 관절 x,y, 배율 x,y (basis/README.md 27~34행)
$parts = @(
  @('Head', 'head', 60, 122, 284, 376, 172, 345, 0.917, 0.917), @('HeadOops', 'head_oops', 340, 122, 567, 376, 453.5, 346, 0.917, 0.917),
  @('HeadDizzy', 'head_dizzy', 623, 122, 850, 376, 736.5, 347, 0.917, 0.917), @('Hat', 'hat', 909, 188, 1190, 314, 1049, 290, 0.94, 0.94),
  @('Feather', 'feather', 1237, 222, 1483, 292, 1194, 303, 0.94, 0.94), @('Torso', 'torso', 109, 493, 365, 861, 236, 853, 1, 1),
  @('Legs', 'legs', 452, 513, 738, 850, 594, 524, 1, 1), @('Arm', 'arm', 840, 519, 936, 793, 888, 559, 0.75, 0.777),
  @('Hand', 'hand', 1061, 585, 1160, 693, 1110, 597, 0.76, 0.76), @('Sword', 'sword', 1263, 469, 1409, 867, 1336, 812, 1, 1))
$k = 0.5935
$growMap = @{}
foreach ($e in ($Grow.Split(';') | Where-Object { $_ })) { $kv = $e.Split('='); $growMap[$kv[0]] = @($kv[1].Split(',') | ForEach-Object { [int]$_ }) }
# -Sheet·-Out: 판 H처럼 고르기 전의 시트는 저장소 밖에 자른다(계획 030b 결정 281)
$sheet = if ($Sheet) { $Sheet } else { Join-Path $BraviRepo 'docs\style\basis\bartolo-parts.png' }
$work = Join-Path $BraviWork '028-cut'; New-Item -ItemType Directory -Force -Path $work | Out-Null
$sheetCut = Join-Path $work 'sheet-cut.png'
if (Test-Path $sheetCut) { Remove-Item $sheetCut }
& (Join-Path $PSScriptRoot 'measure.ps1') -Src $sheet -Cut $sheetCut | ForEach-Object { "sheet $_" }
$outDir = if ($Out) { $Out } else { Join-Path $BraviRepo 'assets\art\opponents\bartolo' }; New-Item -ItemType Directory -Force -Path $outDir | Out-Null
$files = @()
foreach ($p in $parts) {
  $g = if ($growMap.ContainsKey($p[1])) { $growMap[$p[1]] } else { @(0, 0, 0, 0) }
  $x0 = $p[2] - $g[0]; $y0 = $p[3] - $g[1]; $x1 = $p[4] + $g[2]; $y1 = $p[5] + $g[3]
  $out = Join-Path $outDir ($p[1] + '.png'); $files += $out
  $r = [CutParts]::Cut($sheetCut, $sheet, $x0, $y0, $x1, $y1, $out)
  $ratio = if ($r[4] -gt 0) { $r[5] / $r[4] } else { 0 }
  'part,{0},{1},{2},{3},{4},{5:0.0000},{6:0.0000},{7},{8},{9} ({10:P1}),box {11},{12},{13},{14}' -f $p[0], $r[0], $r[1], ($p[6] - $x0), ($p[7] - $y0), ($k * $p[8]), ($k * $p[9]), $r[2], $r[3], $r[5], $ratio, $x0, $y0, $x1, $y1
}
[CutParts]::Board($files, '#3A3027', (Join-Path $work 'board-dark.png'))
[CutParts]::Board($files, '#E9D8B4', (Join-Path $work 'board-parch.png'))
"boards $work"
