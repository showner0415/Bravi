param([string]$Off, [string]$On, [string]$Pts, [string]$Sig)
# Plan 024 T1/T2: the same state baked with the tint filter off and on. Pts lines: name,kind,x,y[,dx,dy]
# fill: 3x3 mean, expect lerp(off, Sig, 0.8). same: 3x3 means equal. line: middle pixel of the first Y<0.22 run in Off.
Add-Type -AssemblyName System.Drawing
if (-not ('TintPair' -as [type])) {
Add-Type -ReferencedAssemblies System.Drawing -TypeDefinition @'
using System; using System.Drawing; using System.Drawing.Imaging; using System.Runtime.InteropServices; using System.Text;
public static class TintPair {
  static byte[] Load(string p, out int st, out int w, out int h) { var b = new Bitmap(p); w = b.Width; h = b.Height; var d = b.LockBits(new Rectangle(0, 0, w, h), ImageLockMode.ReadOnly, PixelFormat.Format32bppArgb); st = d.Stride; var a = new byte[st * h]; Marshal.Copy(d.Scan0, a, 0, a.Length); b.UnlockBits(d); b.Dispose(); return a; }
  static double[] Avg(byte[] px, int st, int x, int y) { double r = 0, g = 0, b = 0; for (int dy = -1; dy <= 1; dy++) for (int dx = -1; dx <= 1; dx++) { int i = (y + dy) * st + (x + dx) * 4; b += px[i]; g += px[i + 1]; r += px[i + 2]; } return new[] { r / 9, g / 9, b / 9 }; }
  static double[] One(byte[] px, int st, int x, int y) { int i = y * st + x * 4; return new double[] { px[i + 2], px[i + 1], px[i] }; }
  static double Yv(double[] c) { return (0.2126 * c[0] + 0.7152 * c[1] + 0.0722 * c[2]) / 255.0; }
  static string F(double[] c) { return string.Format("{0:F0},{1:F0},{2:F0}", c[0], c[1], c[2]); }
  public static string Run(string off, string on, string pts, string sig) {
    int st, w, h, st2, w2, h2; var a = Load(off, out st, out w, out h); var b = Load(on, out st2, out w2, out h2);
    int sr = Convert.ToInt32(sig.Substring(1, 2), 16), sg = Convert.ToInt32(sig.Substring(3, 2), 16), sb = Convert.ToInt32(sig.Substring(5, 2), 16);
    var o = new StringBuilder(); int bad = 0, n = 0;
    foreach (var raw in pts.Split(new[] { '\n', ';' }, StringSplitOptions.RemoveEmptyEntries)) {
      var v = raw.Trim().Split(','); if (v.Length < 4) continue; string name = v[0], kind = v[1]; int x = int.Parse(v[2]), y = int.Parse(v[3]);
      if (raw.Contains("OUT")) { o.AppendLine(name + " (" + kind + "): out of screen, not measured"); continue; }
      n++;
      if (kind == "line") {
        int dx = int.Parse(v[4]), dy = int.Parse(v[5]); int steps = 0, run = 0, sx = 0, sy = 0;
        while (steps < 400 && x > 1 && x < w - 2 && y > 1 && y < h - 2) { if (Yv(One(a, st, x, y)) < 0.22) { if (run == 0) { sx = x; sy = y; } run++; } else if (run > 0) break; x += dx; y += dy; steps++; }
        if (run < 3) { o.AppendLine(string.Format("{0} (line): run {1} px, too thin to measure", name, run)); n--; continue; }
        int mx = sx + dx * (run / 2), my = sy + dy * (run / 2); var c0 = One(a, st, mx, my); var c1 = One(b, st2, mx, my);
        double d = Math.Max(Math.Abs(c0[0] - c1[0]), Math.Max(Math.Abs(c0[1] - c1[1]), Math.Abs(c0[2] - c1[2]))); if (d > 4) bad++;
        o.AppendLine(string.Format("{0} (line): run {1} px at ({2},{3}) off {4} on {5} diff {6:F0} {7}", name, run, mx, my, F(c0), F(c1), d, d <= 4 ? "OK" : "OFF"));
      } else {
        var c0 = Avg(a, st, x, y); var c1 = Avg(b, st2, x, y); double[] e = kind == "fill" ? new[] { c0[0] + (sr - c0[0]) * 0.8, c0[1] + (sg - c0[1]) * 0.8, c0[2] + (sb - c0[2]) * 0.8 } : c0;
        double d = Math.Max(Math.Abs(e[0] - c1[0]), Math.Max(Math.Abs(e[1] - c1[1]), Math.Abs(e[2] - c1[2]))); if (d > 4) bad++;
        o.AppendLine(string.Format("{0} ({1}): ({2},{3}) off {4} Y{5:F2} on {6} expected {7} diff {8:F1} {9}", name, kind, x, y, F(c0), Yv(c0), F(c1), F(e), d, d <= 4 ? "OK" : "OFF"));
      }
    }
    o.AppendLine(string.Format("measured {0}, off {1}", n, bad)); return o.ToString();
  }
}
'@
}
[TintPair]::Run($Off, $On, $Pts, $Sig)
