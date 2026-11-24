param([string]$Sheet, [int]$X, [int]$Y, [int]$W, [int]$H, [int]$OutW = 1920, [int]$OutH = 1080, [double]$Amount = 1.0, [string]$Out, [string]$Old, [switch]$Verify)
# Plan 031b decision 339: cut the stage box from the basis sheet, enlarge it to OutW x OutH (high quality bicubic, edges mirrored),
# then (Amount > 0) re-stand the blurred edges: p + Amount * (p - gaussian sigma 1.0), clamped to the min/max of the 3x3 neighbourhood
# so no halo appears next to a line and flat fills stay as they are. Writes a 24 bit PNG. The basis sheet is not changed. ASCII only.
# Absolute paths only: paths.ps1 is not read because its $w would be the same variable as -W here. -Verify -Out <new> -Old <old> shrinks
# the new image back to the old size (high quality) and prints the per-channel difference (decision 344); it makes nothing.
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
if (-not ('Up031b' -as [type])) { Add-Type -ReferencedAssemblies System.Drawing -TypeDefinition @'
using System; using System.Drawing; using System.Drawing.Imaging; using System.Runtime.InteropServices;
public static class Up031b {
  public static void Sharpen(Bitmap b, double amount) {
    int w = b.Width, h = b.Height; var d = b.LockBits(new Rectangle(0, 0, w, h), ImageLockMode.ReadWrite, PixelFormat.Format24bppRgb); int st = d.Stride;
    var a = new byte[st * h]; Marshal.Copy(d.Scan0, a, 0, a.Length); var tmp = new double[w * h * 3]; var blur = new double[w * h * 3];
    double[] k = { 0.0545, 0.2442, 0.4026, 0.2442, 0.0545 };
    for (int y = 0; y < h; y++) for (int x = 0; x < w; x++) for (int c = 0; c < 3; c++) { double s = 0; for (int i = -2; i <= 2; i++) { int xx = Math.Min(w - 1, Math.Max(0, x + i)); s += k[i + 2] * a[y * st + xx * 3 + c]; } tmp[(y * w + x) * 3 + c] = s; }
    for (int y = 0; y < h; y++) for (int x = 0; x < w; x++) for (int c = 0; c < 3; c++) { double s = 0; for (int i = -2; i <= 2; i++) { int yy = Math.Min(h - 1, Math.Max(0, y + i)); s += k[i + 2] * tmp[(yy * w + x) * 3 + c]; } blur[(y * w + x) * 3 + c] = s; }
    var o = new byte[a.Length]; Array.Copy(a, o, a.Length);
    for (int y = 0; y < h; y++) for (int x = 0; x < w; x++) for (int c = 0; c < 3; c++) { int lo = 255, hi = 0;
      for (int j = -1; j <= 1; j++) for (int i = -1; i <= 1; i++) { int xx = Math.Min(w - 1, Math.Max(0, x + i)), yy = Math.Min(h - 1, Math.Max(0, y + j)); int v = a[yy * st + xx * 3 + c]; if (v < lo) lo = v; if (v > hi) hi = v; }
      double p = a[y * st + x * 3 + c]; double q = p + amount * (p - blur[(y * w + x) * 3 + c]); o[y * st + x * 3 + c] = (byte)Math.Round(Math.Max(lo, Math.Min(hi, q))); }
    Marshal.Copy(o, 0, d.Scan0, o.Length); b.UnlockBits(d); } }
'@ }
if ($Verify) {
  if (-not ('Up031bVerify' -as [type])) { Add-Type -ReferencedAssemblies System.Drawing -TypeDefinition @'
using System; using System.Drawing; using System.Drawing.Imaging; using System.Runtime.InteropServices;
public static class Up031bVerify {
  static byte[] Bytes(Bitmap b, out int st) { var d = b.LockBits(new Rectangle(0, 0, b.Width, b.Height), ImageLockMode.ReadOnly, PixelFormat.Format24bppRgb); var a = new byte[d.Stride * b.Height]; Marshal.Copy(d.Scan0, a, 0, a.Length); st = d.Stride; b.UnlockBits(d); return a; }
  public static double[] Diff(Bitmap a, Bitmap b) { int sa, sb; var x = Bytes(a, out sa); var y = Bytes(b, out sb); var hist = new long[256]; long n = 0; double sum = 0; int max = 0;
    for (int r = 0; r < a.Height; r++) for (int c = 0; c < a.Width * 3; c++) { int d = Math.Abs(x[r * sa + c] - y[r * sb + c]); hist[d]++; n++; sum += d; if (d > max) max = d; }
    long acc = 0; int p99 = 0; for (int i = 0; i < 256; i++) { acc += hist[i]; if (acc >= 0.99 * n) { p99 = i; break; } }
    return new double[] { sum / n, p99, max }; } }
'@ }
  $oldImg = [Drawing.Bitmap]::FromFile($Old); $newImg = [Drawing.Bitmap]::FromFile($Out)
  $back = New-Object Drawing.Bitmap $oldImg.Width, $oldImg.Height, ([Drawing.Imaging.PixelFormat]::Format24bppRgb)
  $vg = [Drawing.Graphics]::FromImage($back); $vg.InterpolationMode = 'HighQualityBicubic'; $vg.PixelOffsetMode = 'HighQuality'; $vg.CompositingMode = 'SourceCopy'
  $va = New-Object Drawing.Imaging.ImageAttributes; $va.SetWrapMode([Drawing.Drawing2D.WrapMode]::TileFlipXY)
  $vg.DrawImage($newImg, (New-Object Drawing.Rectangle 0, 0, $oldImg.Width, $oldImg.Height), 0, 0, $newImg.Width, $newImg.Height, [Drawing.GraphicsUnit]::Pixel, $va); $vg.Dispose()
  $r = [Up031bVerify]::Diff($oldImg, $back); $oldImg.Dispose(); $newImg.Dispose(); $back.Dispose()
  Write-Output ("verify,{0},mean {1:0.00},p99 {2},max {3}" -f (Split-Path -Leaf $Out), $r[0], $r[1], $r[2])
  return
}
$src = [Drawing.Bitmap]::FromFile($Sheet)
$dst = New-Object Drawing.Bitmap $OutW, $OutH, ([Drawing.Imaging.PixelFormat]::Format24bppRgb)
$g = [Drawing.Graphics]::FromImage($dst); $g.InterpolationMode = 'HighQualityBicubic'; $g.PixelOffsetMode = 'HighQuality'; $g.CompositingMode = 'SourceCopy'
$ia = New-Object Drawing.Imaging.ImageAttributes; $ia.SetWrapMode([Drawing.Drawing2D.WrapMode]::TileFlipXY)
$g.DrawImage($src, (New-Object Drawing.Rectangle 0, 0, $OutW, $OutH), $X, $Y, $W, $H, [Drawing.GraphicsUnit]::Pixel, $ia); $g.Dispose(); $src.Dispose()
if ($Amount -gt 0) { [Up031b]::Sharpen($dst, $Amount) }
$dst.Save($Out, [Drawing.Imaging.ImageFormat]::Png); $dst.Dispose()
Write-Output ("upstage,{0},{1}x{2},amount {3}" -f (Split-Path -Leaf $Out), $OutW, $OutH, $Amount)
