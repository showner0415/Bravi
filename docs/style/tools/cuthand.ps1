param([string]$Sheet, [string]$Out, [int]$Grow = 0, [int]$Extend = 0, [double]$Slope = 0, [double]$K = 1, [switch]$Verify)
# Plan 032 v4: cut the player's hand from a generated sheet (background flood fill, tolerance 28, like measure.ps1), thicken the outer
# line by -Grow px (decision 310), lengthen the slanted sleeve by -Extend px along -Slope px/row (decision 305), crop to alpha box + 2 px.
# The sleeve is lengthened by repeating one row two closing-line widths above the lower closing line, the i-th copy pushed round(i*Slope)
# px right; the closing line moves down -Extend and right round(-Extend*Slope). -Verify counts untouched pixels that differ from the cut sheet.
# Joint (decision 303): x = centre of the opaque run 10 rows below the top opaque row, y = top opaque row + Grow. ASCII only.
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'paths.ps1')
Add-Type -AssemblyName System.Drawing
if (-not ('CutHand2' -as [type])) {
Add-Type -ReferencedAssemblies System.Drawing -TypeDefinition @'
using System; using System.Drawing; using System.Drawing.Imaging; using System.Runtime.InteropServices;
public static class CutHand2 {
  static byte[] Load(string p, out int w, out int h) { var b = new Bitmap(p); w = b.Width; h = b.Height;
    var d = b.LockBits(new Rectangle(0, 0, w, h), ImageLockMode.ReadOnly, PixelFormat.Format32bppArgb); var a = new byte[w * h * 4];
    for (int y = 0; y < h; y++) Marshal.Copy(d.Scan0 + y * d.Stride, a, y * w * 4, w * 4); b.UnlockBits(d); b.Dispose(); return a; }
  static double Y(byte[] a, int i) { return (0.2126 * a[i + 2] + 0.7152 * a[i + 1] + 0.0722 * a[i]) / 255; }
  // returns outW, outH, row, N, shift, closing line t, jointX*2, jointY, diff, growPainted
  public static int[] Run(string cutPath, int g, int n, double s, string outPath, bool verify) {
    int W, H; var src = Load(cutPath, out W, out H); var a = (byte[])src.Clone(); var touched = new bool[W * H]; int painted = 0;
    if (g > 0) { int R = g + 1; var dOut = new double[W * H]; var dIn = new double[W * H];
      for (int y = 0; y < H; y++) for (int x = 0; x < W; x++) { bool op = src[(y * W + x) * 4 + 3] >= 128; int rr = op ? 3 : R; double best = 1e9;
        for (int dy = -rr; dy <= rr; dy++) { int yy = y + dy; if (yy < 0 || yy >= H) continue; for (int dx = -rr; dx <= rr; dx++) { int xx = x + dx; if (xx < 0 || xx >= W) continue;
          if ((src[(yy * W + xx) * 4 + 3] >= 128) != op) { double d = Math.Sqrt(dx * dx + dy * dy); if (d < best) best = d; } } }
        if (op) dIn[y * W + x] = best; else dOut[y * W + x] = best; }
      for (int p = 0; p < W * H; p++) { int i = p * 4; bool op = src[i + 3] >= 128; int al = -1;
        if (op && dIn[p] <= 3) al = 255; else if (!op && dOut[p] <= g) al = 255; else if (!op && dOut[p] < g + 1) al = (int)Math.Round((g + 1 - dOut[p]) * 255);
        if (al > 0) { a[i] = 0x1E; a[i + 1] = 0x2A; a[i + 2] = 0x3B; a[i + 3] = (byte)al; touched[p] = true; painted++; } } }
    int y0 = H, y1 = -1, x0 = W, x1 = -1;
    for (int y = 0; y < H; y++) for (int x = 0; x < W; x++) if (a[(y * W + x) * 4 + 3] > 0) { x0 = Math.Min(x0, x); x1 = Math.Max(x1, x); y0 = Math.Min(y0, y); y1 = Math.Max(y1, y); }
    // closing line: dark run going up from the lowest opaque row, in the middle of that row's opaque span
    int bl = W, br = -1; for (int x = 0; x < W; x++) if (a[(y1 * W + x) * 4 + 3] >= 128) { bl = Math.Min(bl, x); br = Math.Max(br, x); }
    int cx = (bl + br) / 2, t = 0; for (int y = y1; y > y0; y--) { int i = (y * W + cx) * 4; if (a[i + 3] >= 128 && Y(a, i) < 0.2) t++; else if (t > 0) break; }
    int row = n > 0 ? y1 - 2 * t : -1, shiftN = (int)Math.Round(n * s);
    int ox0 = Math.Max(0, x0 - 2), oy0 = Math.Max(0, y0 - 2), ow = Math.Min(W - 1, x1 + 2) - ox0 + 1 + shiftN, oh = Math.Min(H - 1, y1 + 2) - oy0 + 1 + n;
    var o = new byte[ow * oh * 4]; var srcRow = new int[oh]; var srcShift = new int[oh];
    for (int oy = 0; oy < oh; oy++) { int y = oy + oy0, sy, sh;
      if (row < 0 || y <= row) { sy = y; sh = 0; } else if (y <= row + n) { sy = row; sh = (int)Math.Round((y - row) * s); } else { sy = y - n; sh = shiftN; }
      srcRow[oy] = sy; srcShift[oy] = sh; if (sy >= H) continue;
      for (int ox = 0; ox < ow; ox++) { int x = ox + ox0 - sh; if (x < 0 || x >= W) continue; Buffer.BlockCopy(a, (sy * W + x) * 4, o, (oy * ow + ox) * 4, 4); } }
    long diff = 0;
    if (verify) for (int oy = 0; oy < oh; oy++) { int y = oy + oy0; if (row >= 0 && y > row && y <= row + n) continue; int sy = srcRow[oy]; if (sy >= H) continue;
      for (int ox = 0; ox < ow; ox++) { int x = ox + ox0 - srcShift[oy]; if (x < 0 || x >= W || touched[sy * W + x]) continue; int p = (oy * ow + ox) * 4, q = (sy * W + x) * 4;
        if (src[q + 3] == 0 && o[p + 3] == 0) continue; if (o[p] != src[q] || o[p + 1] != src[q + 1] || o[p + 2] != src[q + 2] || o[p + 3] != src[q + 3]) diff++; } }
    int top = 0; for (; top < oh; top++) { bool any = false; for (int ox = 0; ox < ow; ox++) if (o[(top * ow + ox) * 4 + 3] >= 128) { any = true; break; } if (any) break; }
    int jl = ow, jr = -1; for (int ox = 0; ox < ow; ox++) if (o[((top + 10) * ow + ox) * 4 + 3] >= 128) { jl = Math.Min(jl, ox); jr = Math.Max(jr, ox); }
    var bm = new Bitmap(ow, oh, PixelFormat.Format32bppArgb); var od = bm.LockBits(new Rectangle(0, 0, ow, oh), ImageLockMode.WriteOnly, PixelFormat.Format32bppArgb);
    for (int y = 0; y < oh; y++) Marshal.Copy(o, y * ow * 4, od.Scan0 + y * od.Stride, ow * 4); bm.UnlockBits(od); bm.Save(outPath, ImageFormat.Png); bm.Dispose();
    return new int[] { ow, oh, row < 0 ? -1 : row - oy0, n, shiftN, t, jl + jr, top + g, (int)diff, painted };
  }
}
'@
}
$work = Join-Path $BraviWork '032-cut'; New-Item -ItemType Directory -Force -Path $work | Out-Null
$sheetCut = Join-Path $work 'sheet-cut.png'; if (Test-Path $sheetCut) { Remove-Item $sheetCut }
& (Join-Path $PSScriptRoot 'measure.ps1') -Src $Sheet -Cut $sheetCut | ForEach-Object { "sheet $_" }
New-Item -ItemType Directory -Force -Path (Split-Path $Out) | Out-Null
$r = [CutHand2]::Run($sheetCut, $Grow, $Extend, $Slope, $Out, [bool]$Verify)
'hand,{0}x{1},grow {2} px ({3} painted),repeated row {4},inserted {5} px ({6:0.0} units),shift {7} px,closing line {8} px,joint {9:0.0},{10}{11}' -f $r[0], $r[1], $Grow, $r[9], $r[2], $r[3], ($r[3] / $K), $r[4], $r[5], ($r[6] / 2.0), $r[7], $(if ($Verify) { ",diff $($r[8])" } else { '' })
