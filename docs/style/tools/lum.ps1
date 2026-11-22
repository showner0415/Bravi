param([string]$Img, [string]$Rects)
# 계획 021 H7: 상대 휘도 L(선형)의 평균·95번째 값, 그림 전체의 신호 구역 화소 비율
Add-Type -AssemblyName System.Drawing
if (-not ('Lum' -as [type])) {
Add-Type -ReferencedAssemblies System.Drawing -TypeDefinition @'
using System; using System.Drawing; using System.Drawing.Imaging; using System.Runtime.InteropServices; using System.Collections.Generic;
public static class Lum {
  static double Lin(int c) { double v = c / 255.0; return v <= 0.04045 ? v / 12.92 : Math.Pow((v + 0.055) / 1.055, 2.4); }
  static byte[] Load(string p, out int st, out int w, out int h) { var b = new Bitmap(p); w = b.Width; h = b.Height; var d = b.LockBits(new Rectangle(0, 0, w, h), ImageLockMode.ReadOnly, PixelFormat.Format32bppArgb); st = d.Stride; var a = new byte[st * h]; Marshal.Copy(d.Scan0, a, 0, a.Length); b.UnlockBits(d); b.Dispose(); return a; }
  public static string Rect(string p, string name, int x0, int y0, int x1, int y1) {
    int st, w, h; var px = Load(p, out st, out w, out h); var L = new List<double>();
    for (int y = y0; y < y1; y++) for (int x = x0; x < x1; x++) { int i = y * st + x * 4; L.Add(0.2126 * Lin(px[i + 2]) + 0.7152 * Lin(px[i + 1]) + 0.0722 * Lin(px[i])); }
    L.Sort(); double s = 0; foreach (var v in L) s += v;
    return string.Format("{0}: mean L {1:F3}  p95 {2:F3}  max {3:F3}  n {4}", name, s / L.Count, L[L.Count * 95 / 100], L[L.Count - 1], L.Count);
  }
  public static string Sig(string p) {
    int st, w, h; var px = Load(p, out st, out w, out h); int n = 0;
    for (int y = 0; y < h; y++) for (int x = 0; x < w; x++) { int i = y * st + x * 4; double r = px[i + 2] / 255.0, g = px[i + 1] / 255.0, b = px[i] / 255.0; double mx = Math.Max(r, Math.Max(g, b)), mn = Math.Min(r, Math.Min(g, b)); if (mx >= 0.85 && (mx - mn) / mx >= 0.55) n++; }
    return string.Format("sigZone {0} of {1} ({2:P3})", n, w * h, (double)n / (w * h));
  }
}
'@
}
[Lum]::Sig($Img)
foreach ($r in $Rects.Split(';')) { $p = $r.Split(','); [Lum]::Rect($Img, $p[0], [int]$p[1], [int]$p[2], [int]$p[3], [int]$p[4]) }
