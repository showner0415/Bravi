param([string]$Img, [string]$Cols = '', [string]$Rows = '')
# 관절 자리를 읽으려고 세로줄·가로줄을 따라 바탕/선/칠의 경계를 낸다(계획 021 작업 7).
Add-Type -AssemblyName System.Drawing
if (-not ('Scan' -as [type])) {
Add-Type -ReferencedAssemblies System.Drawing -TypeDefinition @'
using System; using System.Drawing; using System.Drawing.Imaging; using System.Runtime.InteropServices; using System.Text;
public static class Scan {
  public static string Line(string path, bool vertical, int at, int a, int b) {
    var bm = new Bitmap(path); var d = bm.LockBits(new Rectangle(0, 0, bm.Width, bm.Height), ImageLockMode.ReadOnly, PixelFormat.Format32bppArgb);
    int st = d.Stride; var px = new byte[st * bm.Height]; Marshal.Copy(d.Scan0, px, 0, px.Length); bm.UnlockBits(d); bm.Dispose();
    var sb = new StringBuilder(); string prev = null; int start = a;
    for (int t = a; t <= b; t++) {
      int x = vertical ? at : t, y = vertical ? t : at; int i = y * st + x * 4; string k;
      if (px[i + 3] < 128) k = "bg"; else { double Y = (0.2126 * px[i + 2] + 0.7152 * px[i + 1] + 0.0722 * px[i]) / 255; k = Y < 0.2 ? "LINE" : string.Format("#{0:X2}{1:X2}{2:X2}", px[i + 2] & 0xF0, px[i + 1] & 0xF0, px[i] & 0xF0); }
      if (k != prev) { if (prev != null && t - 1 > start) sb.AppendFormat("{0}-{1}:{2}  ", start, t - 1, prev); prev = k; start = t; }
    }
    sb.AppendFormat("{0}-{1}:{2}", start, b, prev); return sb.ToString();
  }
}
'@
}
foreach ($c in ($Cols.Split(';') | Where-Object { $_ })) { $p = $c.Split(','); "x$($p[0]) [$($p[1])-$($p[2])]: " + [Scan]::Line($Img, $true, [int]$p[0], [int]$p[1], [int]$p[2]) }
foreach ($r in ($Rows.Split(';') | Where-Object { $_ })) { $p = $r.Split(','); "y$($p[0]) [$($p[1])-$($p[2])]: " + [Scan]::Line($Img, $false, [int]$p[0], [int]$p[1], [int]$p[2]) }
