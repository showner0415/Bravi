param([string]$Sheet, [int]$X, [int]$Y, [Alias('W')][int]$Width, [Alias('H')][int]$Height, [string]$Out, [switch]$Verify)
# Plan 031 decision 296: cut a 16:9 stage out of a basis sheet as it is, no filtering or scaling (decision 251). ASCII only.
# Without -Verify: writes <Out> (24-bit PNG). With -Verify: compares <Out> with the same box of <Sheet> pixel by pixel and prints "diff <n>".
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'paths.ps1')
Add-Type -AssemblyName System.Drawing
if (-not ('CutStage' -as [type])) {
Add-Type -ReferencedAssemblies System.Drawing -TypeDefinition @'
using System; using System.Drawing; using System.Drawing.Imaging; using System.Runtime.InteropServices;
public static class CutStage {
  static byte[] Load(Bitmap b, out int st) {
    var d = b.LockBits(new Rectangle(0, 0, b.Width, b.Height), ImageLockMode.ReadOnly, PixelFormat.Format24bppRgb);
    st = d.Stride; var a = new byte[st * b.Height]; Marshal.Copy(d.Scan0, a, 0, a.Length); b.UnlockBits(d); return a;
  }
  public static string Cut(string sheet, int x, int y, int w, int h, string outPath) {
    using (var s = new Bitmap(sheet)) using (var c = s.Clone(new Rectangle(x, y, w, h), PixelFormat.Format24bppRgb)) { c.Save(outPath, ImageFormat.Png); return w + "x" + h; }
  }
  public static long Verify(string sheet, int x, int y, int w, int h, string cutPath) {
    using (var s = new Bitmap(sheet)) using (var c = new Bitmap(cutPath)) {
      if (c.Width != w || c.Height != h) return -1;
      int ss, cs; var a = Load(s, out ss); var b = Load(c, out cs); long n = 0;
      for (int j = 0; j < h; j++) for (int i = 0; i < w; i++) { int p = (y + j) * ss + (x + i) * 3, q = j * cs + i * 3;
        if (a[p] != b[q] || a[p + 1] != b[q + 1] || a[p + 2] != b[q + 2]) n++; }
      return n;
    }
  }
}
'@
}
if ($Verify) { "verify,$([IO.Path]::GetFileName($Out)),diff $([CutStage]::Verify($Sheet, $X, $Y, $Width, $Height, $Out))" }
else { New-Item -ItemType Directory -Force -Path (Split-Path $Out) | Out-Null; "cut,$([IO.Path]::GetFileName($Out)),$([CutStage]::Cut($Sheet, $X, $Y, $Width, $Height, $Out)),box $X,$Y,$Width,$Height" }
