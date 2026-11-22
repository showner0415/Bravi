param([string]$Sheet = '', [string]$Rows = 'upgrip=568;upcuff=675;thrustcuff=351', [string]$Out = '', [string]$Layout = '')
# 계획 030 작업 2: 팔 시트(basis/bartolo-arms.png)에서 따로 그린 팔 일곱 장을 잘라 assets/art/opponents/bartolo/에 둔다(결정 267).
# 바탕은 measure.ps1로 지우고(허용 차 28) 화소를 줄이지 않는다(결정 251). 이어진 그림을 행에서 가르므로 자른 선 위의 불투명은 0이 아닌 것이 맞다(T2).
# -Rows: upgrip = 1번 날밑 아래 선의 마지막 행, upcuff = 1번 소맷부리 위 선의 첫 행, thrustcuff = 2번 소맷부리 아래 선의 마지막 행.
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'paths.ps1')
if (-not $Sheet) { $Sheet = Join-Path $BraviRepo 'docs\style\basis\bartolo-arms.png' }
Add-Type -AssemblyName System.Drawing
if (-not ('CutArms' -as [type])) {
Add-Type -ReferencedAssemblies System.Drawing -TypeDefinition @'
using System; using System.Drawing; using System.Drawing.Imaging; using System.Runtime.InteropServices;
public static class CutArms {
  public static byte[] Load(string p, out int st, out int w, out int h) {
    var b = new Bitmap(p); w = b.Width; h = b.Height;
    var d = b.LockBits(new Rectangle(0, 0, w, h), ImageLockMode.ReadOnly, PixelFormat.Format32bppArgb);
    st = d.Stride; var a = new byte[st * h]; Marshal.Copy(d.Scan0, a, 0, a.Length); b.UnlockBits(d); b.Dispose(); return a;
  }
  // 2번 주먹과 날밑의 경계(세로줄마다): 살갗이 끝나는 행 + 4 = 맞닿은 두 선의 가운데. 살갗이 없는 줄은 가까운 줄의 값, 주먹이 없는 줄은 -1
  static int[] split; static int splitX0;
  public static string SetSplit(string cutPath, int x0, int x1, int y0, int y1, int yTop) {
    int st, W, H; var c = Load(cutPath, out st, out W, out H); split = new int[x1 - x0 + 1]; splitX0 = x0; var has = new bool[split.Length];
    for (int x = x0; x <= x1; x++) { int last = -1; bool any = false;
      for (int y = y0; y <= y1; y++) { int i = y * st + x * 4; if (c[i + 3] == 0) continue; if (y <= yTop) any = true; int r = c[i + 2], g = c[i + 1], b = c[i]; if (r >= 200 && g >= 140 && r - b >= 60) last = y; }
      split[x - x0] = last >= 0 ? last + 4 : -1; has[x - x0] = any; }
    for (int k = 0; k < split.Length; k++) if (split[k] < 0 && has[k]) { for (int d = 1; d < split.Length; d++) { if (k - d >= 0 && split[k - d] >= 0 && has[k - d]) { split[k] = split[k - d]; break; } if (k + d < split.Length && split[k + d] >= 0 && has[k + d]) { split[k] = split[k + d]; break; } } }
    int mn = 9999, mx = -1; foreach (int v in split) if (v >= 0) { mn = Math.Min(mn, v); mx = Math.Max(mx, v); } return "split " + mn + ".." + mx;
  }
  static bool Guard(int x, int y, double cx, double cy, double rx, double ry) { if (E(x, y, cx, cy, rx, ry) > 1) return false; int k = x - splitX0; int s = split != null && k >= 0 && k < split.Length ? split[k] : -1; return y > s; }
  // 칼날이 주먹 아래를 비스듬히 지날 때(계획 030c 3번 팔): 칼날 쪽 = 위 점 위로는 x > 위 점, 아래로는 위 점 → 아래 점 선의 오른쪽
  static bool lineOn; static double lx0, ly0, lx1, ly1; static int bx0, by0, bx1, by1;
  public static void SetLine(bool on, double x0, double y0, double x1, double y1, int b0, int b1, int b2, int b3) { lineOn = on; lx0 = x0; ly0 = y0; lx1 = x1; ly1 = y1; bx0 = b0; by0 = b1; bx1 = b2; by1 = b3; }
  static bool BladeSide(int x, int y) { double px = x + 0.5, py = y + 0.5; if (py < ly0) return px > lx0; return (lx1 - lx0) * (py - ly0) - (ly1 - ly0) * (px - lx0) < 0; }
  // 기운 날밑(계획 030c 3번 팔)은 타원을 돌려 맞춘다. 0°면 셈이 지금과 화소까지 같다(결정 292)
  static double rc = 1, rs = 0;
  public static void SetRot(double deg) { rc = Math.Cos(deg * Math.PI / 180); rs = Math.Sin(deg * Math.PI / 180); if (deg == 0) { rc = 1; rs = 0; } }
  static double E(int x, int y, double cx, double cy, double rx, double ry) { double dx = x + 0.5 - cx, dy = y + 0.5 - cy; double u = (dx * rc + dy * rs) / rx, v = (dy * rc - dx * rs) / ry; return u * u + v * v; }
  // mode 0 상자, 1 상자에서 타원을 뺌, 2 타원 안. cut: 자른 변(1 위, 2 아래, 4 왼, 8 오른, 16 타원 둘레)
  // 반환: 폭, 높이, 자른 선이 아닌 변의 불투명, 자른 선 위의 불투명, RGB 다름, 경계 화소, 경계의 밝은 화소
  public static int[] Cut(string cutPath, string srcPath, int x0, int y0, int x1, int y1, int mode, double cx, double cy, double rx, double ry, int cut, string outPath) {
    int cst, W, H, sst, sw, sh; var c = Load(cutPath, out cst, out W, out H); var s = Load(srcPath, out sst, out sw, out sh);
    int w = x1 - x0 + 1, h = y1 - y0 + 1; var o = new Bitmap(w, h, PixelFormat.Format32bppArgb);
    var od = o.LockBits(new Rectangle(0, 0, w, h), ImageLockMode.WriteOnly, PixelFormat.Format32bppArgb); int ost = od.Stride; var a = new byte[ost * h];
    int edge = 0, cutEdge = 0, diff = 0, border = 0, bright = 0;
    for (int y = 0; y < h; y++) for (int x = 0; x < w; x++) {
      int sx = x0 + x, sy = y0 + y; if (sx < 0 || sy < 0 || sx >= W || sy >= H) continue;
      double e = E(sx, sy, cx, cy, rx, ry);
      if (mode == 1 && e <= 1) continue; if (mode == 2 && e > 1) continue;
      if (mode == 3 && Guard(sx, sy, cx, cy, rx, ry)) continue; if (mode == 4 && !Guard(sx, sy, cx, cy, rx, ry)) continue;
      if (lineOn && mode == 1 && !BladeSide(sx, sy)) continue;
      if (lineOn && mode == 3 && sx >= bx0 && sx <= bx1 && sy >= by0 && sy <= by1 && BladeSide(sx, sy)) continue;
      int ci = sy * cst + sx * 4, oi = y * ost + x * 4; if (c[ci + 3] == 0) continue;
      for (int k = 0; k < 4; k++) a[oi + k] = c[ci + k];
      int si = sy * sst + sx * 4; if (c[ci] != s[si] || c[ci + 1] != s[si + 1] || c[ci + 2] != s[si + 2]) diff++;
      bool onCut = (y == 0 && (cut & 1) != 0) || (y == h - 1 && (cut & 2) != 0) || (x == 0 && (cut & 4) != 0) || (x == w - 1 && (cut & 8) != 0)
        || ((cut & 16) != 0 && (mode == 1 ? E(sx, sy, cx, cy, rx, ry) <= 1.08 : E(sx, sy, cx, cy, rx, ry) >= 0.92));
      if ((cut & 32) != 0 && (mode == 3 ? Guard(sx, sy + 1, cx, cy, rx, ry) : !Guard(sx, sy - 1, cx, cy, rx, ry))) onCut = true;
      bool onSide = y == 0 || y == h - 1 || x == 0 || x == w - 1;
      if (onCut) cutEdge++; else if (onSide) edge++;
    }
    int[] dx = { -1, 1, 0, 0 }, dy = { 0, 0, -1, 1 };
    for (int y = 0; y < h; y++) for (int x = 0; x < w; x++) {
      int oi = y * ost + x * 4; if (a[oi + 3] == 0) continue; bool nearT = false;
      for (int k = 0; k < 4; k++) { int nx = x + dx[k], ny = y + dy[k]; if (nx < 0 || ny < 0 || nx >= w || ny >= h || a[ny * ost + nx * 4 + 3] == 0) { nearT = true; break; } }
      if (!nearT) continue; border++;
      double Yv = (0.2126 * a[oi + 2] + 0.7152 * a[oi + 1] + 0.0722 * a[oi]) / 255.0; if (Yv >= 0.6) bright++;
    }
    Marshal.Copy(a, 0, od.Scan0, a.Length); o.UnlockBits(od); o.Save(outPath, ImageFormat.Png); o.Dispose();
    return new int[] { w, h, edge, cutEdge, diff, border, bright };
  }
  // 잘린 장들을 시트의 자리로 다시 놓아 바탕 지운 시트와 견준다: 겹친 화소가 다른 수, 덮이지 않은 불투명 수(상자 안)
  public static int[] Recompose(string cutPath, string[] files, int[] xs, int[] ys, int[] boxes) {
    int st, W, H; var c = Load(cutPath, out st, out W, out H);
    var have = new bool[W * H]; int mismatch = 0;
    for (int f = 0; f < files.Length; f++) {
      int pst, pw, ph; var p = Load(files[f], out pst, out pw, out ph);
      for (int y = 0; y < ph; y++) for (int x = 0; x < pw; x++) {
        int pi = y * pst + x * 4; if (p[pi + 3] == 0) continue; int sx = xs[f] + x, sy = ys[f] + y; int ci = sy * st + sx * 4;
        if (p[pi] != c[ci] || p[pi + 1] != c[ci + 1] || p[pi + 2] != c[ci + 2] || p[pi + 3] != c[ci + 3]) mismatch++;
        have[sy * W + sx] = true;
      }
    }
    int uncovered = 0;
    for (int b = 0; b < boxes.Length; b += 4) for (int y = boxes[b + 1]; y <= boxes[b + 3]; y++) for (int x = boxes[b]; x <= boxes[b + 2]; x++)
      if (c[y * st + x * 4 + 3] != 0 && !have[y * W + x]) uncovered++;
    return new int[] { mismatch, uncovered };
  }
}
'@
}
$row = @{}; foreach ($e in ($Rows.Split(';') | Where-Object { $_ })) { $kv = $e.Split('='); $row[$kv[0]] = [int]$kv[1] }
$k = 0.5333 * 0.5935
# -Layout <.psd1>: 팔마다 Kind(up = 1번 팔의 규칙, forward = 2번 팔의 규칙)와 시트의 값(계획 030c 결정 292). 없으면 지금 시트의 두 팔이다.
# up: 칼 x0,y0,x1 · 소매 x0,x1,y1 · 주먹 x0,x1, Grip(날밑 아래 선의 마지막 행), Cuff(소맷부리 위 선의 첫 행). 1번 주먹은 왼쪽 윤곽이 x 390 밖으로 나와 384부터.
# forward: 소매 x0,y0,x1, Cuff(소맷부리 아래 선의 마지막 행), 날밑 타원 cx,cy,rx,ry[,기울기°], Split(살갗을 찾는 아래 행, 주먹이 있는 위 행), 칼날 상자, 고를 때만 Cuts·BladeLine(위 점 x,y, 아래 점 x,y).
# 칼날은 상자 위쪽이 날밑 타원 안이라 타원을 빼고 자른다(타원 안은 날밑 장이 맡는다).
$arms = if ($Layout) { (Import-PowerShellDataFile $Layout).Arms } else { @(
  @{ Kind = 'up'; Name = 'ArmUp'; File = 'arm_up'; Joint = @(455, 923); Grip = $row.upgrip; Cuff = $row.upcuff; Sword = @(372, 14, 534); Sleeve = @(390, 532, 982); Fist = @(384, 532); Box = @(372, 14, 534, 982) },
  @{ Kind = 'forward'; Name = 'ArmThrust'; File = 'arm_thrust'; Joint = @(1098, 250); Cuff = $row.thrustcuff; Sleeve = @(985, 188, 1215); Guard = @(1098, 500, 112, 58); Split = @(480, 440); Blade = @(1068, 540, 1132, 814); Box = @(985, 188, 1215, 814) }) }
$work = Join-Path $BraviWork '030-cut'; New-Item -ItemType Directory -Force -Path $work | Out-Null
$sheetCut = Join-Path $work 'sheet-cut.png'
if (Test-Path $sheetCut) { Remove-Item $sheetCut }
& (Join-Path $PSScriptRoot 'measure.ps1') -Src $Sheet -Cut $sheetCut | ForEach-Object { "sheet $_" }
# -Out: 판 H처럼 고르기 전의 시트는 저장소 밖에 자른다(계획 030b 결정 281)
$outDir = if ($Out) { $Out } else { Join-Path $BraviRepo 'assets\art\opponents\bartolo' }
New-Item -ItemType Directory -Force -Path $outDir | Out-Null
$files = @(); $xs = @(); $ys = @(); $boxes = @()
foreach ($a in $arms) {
  $j = $a.Joint; $n = $a.Name; $f = $a.File; $g = @(1, 1, 1, 1)
  # 이름, 파일, 상자 x0,y0,x1,y1, mode, 자른 변
  if ($a.Kind -eq 'up') {
    $parts = @(@("${n}Sword", "${f}_sword", $a.Sword[0], $a.Sword[1], $a.Sword[2], $a.Grip, 0, 2), @($n, $f, $a.Sleeve[0], $a.Cuff, $a.Sleeve[1], $a.Sleeve[2], 0, 1),
      @("${n}Fist", "${f}_fist", $a.Fist[0], ($a.Grip + 1), $a.Fist[1], ($a.Cuff + 2), 0, 3))
  } else {
    $g = $a.Guard; $s = $a.Sleeve; $b = $a.Blade; $rot = if ($g.Count -gt 4) { [double]$g[4] } else { 0 }; [CutArms]::SetRot($rot)
    "guard $n " + [CutArms]::SetSplit($sheetCut, $s[0], $s[2], ($a.Cuff + 1), $a.Split[0], $a.Split[1])
    # 돌린 타원의 상자 반폭(가로·세로)
    $hx = $g[2]; $hy = $g[3]; if ($rot -ne 0) { $cr = [math]::Cos($rot * [math]::PI / 180); $sr = [math]::Sin($rot * [math]::PI / 180)
      $hx = [math]::Ceiling([math]::Sqrt([math]::Pow($g[2] * $cr, 2) + [math]::Pow($g[3] * $sr, 2))); $hy = [math]::Ceiling([math]::Sqrt([math]::Pow($g[2] * $sr, 2) + [math]::Pow($g[3] * $cr, 2))) }
    # Cuts: 주먹·칼날 장에 더할 자른 변(칼날이 주먹 옆을 비스듬히 지나 세로줄에서 가를 때, 3번 팔)
    $cx = if ($a.Cuts) { $a.Cuts } else { @(0, 0) }
    $bl = $a.BladeLine; if ($bl) { [CutArms]::SetLine($true, $bl[0], $bl[1], $bl[2], $bl[3], $b[0], $b[1], $b[2], $b[3]) } else { [CutArms]::SetLine($false, 0, 0, 0, 0, 0, 0, -1, -1) }
    $parts = @(@($n, $f, $s[0], $s[1], $s[2], $a.Cuff, 0, 2), @("${n}Fist", "${f}_fist", $s[0], ($a.Cuff - 2), $s[2], $g[1], 3, (33 -bor $cx[0])),
      @("${n}Sword", "${f}_sword", ($g[0] - $hx), ($g[1] - $hy), ($g[0] + $hx), ($g[1] + $hy), 4, 48), @("${n}Blade", "${f}_blade", $b[0], $b[1], $b[2], $b[3], 1, (16 -bor $cx[1])))
  }
  foreach ($p in $parts) {
    $out = Join-Path $outDir ($p[1] + '.png'); $files += $out; $xs += $p[2]; $ys += $p[3]
    $r = [CutArms]::Cut($sheetCut, $Sheet, $p[2], $p[3], $p[4], $p[5], $p[6], $g[0], $g[1], $g[2], $g[3], $p[7], $out)
    'part,{0},{1},{2},joint {3},{4},upp {5:0.0000},edge {6},cut-line {7},diff {8},bright {9}/{10},box {11},{12},{13},{14}' -f $p[0], $r[0], $r[1], ($j[0] - $p[2]), ($j[1] - $p[3]), $k, $r[2], $r[3], $r[4], $r[6], $r[5], $p[2], $p[3], $p[4], $p[5]
  }
  $boxes += $a.Box
}
$m = [CutArms]::Recompose($sheetCut, [string[]]$files, [int[]]$xs, [int[]]$ys, [int[]]$boxes)
'recompose,mismatch {0},uncovered {1}' -f $m[0], $m[1]
