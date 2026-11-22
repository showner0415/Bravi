param([string]$Src, [string]$Cut, [int]$Tol = 28, [string]$Regions = '')
# 怨꾪쉷 021 ?묒뾽 7???ш린: ?뚮몢由?梨꾩슦湲곕줈 諛뷀깢 吏?곌린(H3), ?좏샇 援ъ뿭 ?붿냼(H5), ??硫댁쓽 移졖룰렇由쇱옄 ??H5쨌H8)
Add-Type -AssemblyName System.Drawing
if (-not ('Meas' -as [type])) {
Add-Type -ReferencedAssemblies System.Drawing -TypeDefinition @'
using System; using System.Drawing; using System.Drawing.Imaging; using System.Collections.Generic; using System.Runtime.InteropServices;
public static class Meas {
  static byte[] Load(Bitmap b, out int stride) {
    var d = b.LockBits(new Rectangle(0, 0, b.Width, b.Height), ImageLockMode.ReadOnly, PixelFormat.Format32bppArgb);
    stride = d.Stride; var a = new byte[stride * b.Height]; Marshal.Copy(d.Scan0, a, 0, a.Length); b.UnlockBits(d); return a;
  }
  public static double Y(int r, int g, int b) { return (0.2126 * r + 0.7152 * g + 0.0722 * b) / 255.0; }
  public static string Cut(string src, string dst, int tol) {
    var b0 = new Bitmap(src); var b = new Bitmap(b0.Width, b0.Height, PixelFormat.Format32bppArgb);
    using (var g = Graphics.FromImage(b)) g.DrawImage(b0, 0, 0, b0.Width, b0.Height); b0.Dispose();
    int st; var px = Load(b, out st); int W = b.Width, H = b.Height;
    var rs = new List<int>(); var gs = new List<int>(); var bs = new List<int>();
    for (int x = 0; x < W; x++) foreach (int y in new[] { 0, H - 1 }) { int i = y * st + x * 4; bs.Add(px[i]); gs.Add(px[i + 1]); rs.Add(px[i + 2]); }
    for (int y = 0; y < H; y++) foreach (int x in new[] { 0, W - 1 }) { int i = y * st + x * 4; bs.Add(px[i]); gs.Add(px[i + 1]); rs.Add(px[i + 2]); }
    rs.Sort(); gs.Sort(); bs.Sort(); int R = rs[rs.Count / 2], G = gs[gs.Count / 2], B = bs[bs.Count / 2];
    int rsp = rs[rs.Count * 95 / 100] - rs[rs.Count * 5 / 100];
    var bg = new bool[W * H]; var q = new Queue<int>();
    Func<int, bool> near = k => { int i = (k / W) * st + (k % W) * 4; return Math.Abs(px[i + 2] - R) <= tol && Math.Abs(px[i + 1] - G) <= tol && Math.Abs(px[i] - B) <= tol; };
    for (int x = 0; x < W; x++) { foreach (int y in new[] { 0, H - 1 }) { int k = y * W + x; if (!bg[k] && near(k)) { bg[k] = true; q.Enqueue(k); } } }
    for (int y = 0; y < H; y++) { foreach (int x in new[] { 0, W - 1 }) { int k = y * W + x; if (!bg[k] && near(k)) { bg[k] = true; q.Enqueue(k); } } }
    while (q.Count > 0) { int k = q.Dequeue(); int x = k % W, y = k / W;
      if (x > 0 && !bg[k - 1] && near(k - 1)) { bg[k - 1] = true; q.Enqueue(k - 1); }
      if (x < W - 1 && !bg[k + 1] && near(k + 1)) { bg[k + 1] = true; q.Enqueue(k + 1); }
      if (y > 0 && !bg[k - W] && near(k - W)) { bg[k - W] = true; q.Enqueue(k - W); }
      if (y < H - 1 && !bg[k + W] && near(k + W)) { bg[k + W] = true; q.Enqueue(k + W); } }
    var ring = new bool[W * H];
    for (int y = 1; y < H - 1; y++) for (int x = 1; x < W - 1; x++) { int k = y * W + x; if (!bg[k] && (bg[k - 1] || bg[k + 1] || bg[k - W] || bg[k + W])) ring[k] = true; }
    int fig = 0, sigz = 0;
    for (int k = 0; k < W * H; k++) { int i = (k / W) * st + (k % W) * 4;
      if (bg[k] || ring[k]) { px[i + 3] = 0; continue; }
      fig++; double r = px[i + 2] / 255.0, gg = px[i + 1] / 255.0, bb = px[i] / 255.0; double mx = Math.Max(r, Math.Max(gg, bb)), mn = Math.Min(r, Math.Min(gg, bb));
      double s = mx == 0 ? 0 : (mx - mn) / mx; if (s >= 0.55 && mx >= 0.85) sigz++; }
    var d = b.LockBits(new Rectangle(0, 0, W, H), ImageLockMode.WriteOnly, PixelFormat.Format32bppArgb); Marshal.Copy(px, 0, d.Scan0, px.Length); b.UnlockBits(d);
    b.Save(dst, ImageFormat.Png);
    int c0 = px[3], c1 = px[(W - 1) * 4 + 3], c2 = px[(H - 1) * st + 3], c3 = px[(H - 1) * st + (W - 1) * 4 + 3];
    b.Dispose();
    return string.Format("size {0}x{1} bg #{2:X2}{3:X2}{4:X2} borderSpreadR {5} figurePx {6} ({7:P1}) sigZone {8} ({9:P2}) cornersAlpha {10},{11},{12},{13}", W, H, R, G, B, rsp, fig, (double)fig / (W * H), sigz, fig == 0 ? 0 : (double)sigz / fig, c0, c1, c2, c3);
  }
  // ???곸옄 ?덉쓽 移좎쓣 諛앷린濡???移졖룰렇由쇱옄)濡??섎닠 媛?대뜲 媛믨낵 ???먯뵫???몃떎. ??Y < 0.12)? 類??
  public static string Region(string cut, string name, int x0, int y0, int x1, int y1) {
    var b = new Bitmap(cut); int st; var px = Load(b, out st);
    var pts = new List<int[]>();
    for (int y = y0; y < y1; y++) for (int x = x0; x < x1; x++) { int i = y * st + x * 4; if (px[i + 3] < 250) continue; int r = px[i + 2], g = px[i + 1], bl = px[i]; if (Y(r, g, bl) < 0.12) continue; pts.Add(new[] { x, y, r, g, bl }); }
    b.Dispose();
    if (pts.Count < 20) return name + ": too few";
    pts.Sort((a, c) => Y(a[2], a[3], a[4]).CompareTo(Y(c[2], c[3], c[4])));
    double lo = Y(pts[pts.Count / 10][2], pts[pts.Count / 10][3], pts[pts.Count / 10][4]), hi = Y(pts[pts.Count * 9 / 10][2], pts[pts.Count * 9 / 10][3], pts[pts.Count * 9 / 10][4]);
    for (int it = 0; it < 12; it++) { double sl = 0, sh = 0; int nl = 0, nh = 0; double mid = (lo + hi) / 2;
      foreach (var p in pts) { double v = Y(p[2], p[3], p[4]); if (v < mid) { sl += v; nl++; } else { sh += v; nh++; } }
      if (nl > 0) lo = sl / nl; if (nh > 0) hi = sh / nh; }
    double m = (lo + hi) / 2; var dark = pts.FindAll(p => Y(p[2], p[3], p[4]) < m); var light = pts.FindAll(p => Y(p[2], p[3], p[4]) >= m);
    Func<List<int[]>, string, string> desc = (L, lab) => {
      if (L.Count == 0) return lab + " none";
      var srt = new List<int[]>(L); srt.Sort((a, c) => Y(a[2], a[3], a[4]).CompareTo(Y(c[2], c[3], c[4])));
      var md = srt[srt.Count / 2]; double s = 0; { double r = md[2] / 255.0, g = md[3] / 255.0, bb = md[4] / 255.0; double mx = Math.Max(r, Math.Max(g, bb)), mn = Math.Min(r, Math.Min(g, bb)); s = mx == 0 ? 0 : (mx - mn) / mx; }
      var p1 = srt[srt.Count / 4]; var p2 = srt[srt.Count / 2]; var p3 = srt[srt.Count * 3 / 4]; var p05 = srt[srt.Count / 20];
      return string.Format("{0} n{1} median #{2:X2}{3:X2}{4:X2} Y{5:F2} S{6:F0}% | pts ({7},{8})Y{9:F2} ({10},{11})Y{12:F2} ({13},{14})Y{15:F2} | p5 Y{16:F2}", lab, L.Count, md[2], md[3], md[4], Y(md[2], md[3], md[4]), s * 100,
        p1[0], p1[1], Y(p1[2], p1[3], p1[4]), p2[0], p2[1], Y(p2[2], p2[3], p2[4]), p3[0], p3[1], Y(p3[2], p3[3], p3[4]), Y(p05[2], p05[3], p05[4]));
    };
    return name + ": " + desc(light, "fill") + " || " + desc(dark, "shadow");
  }
}
'@
}
if ($Src -and $Cut) { [Meas]::Cut($Src, $Cut, $Tol) }
if ($Regions) {
  foreach ($r in $Regions.Split(';')) { $p = $r.Split(','); [Meas]::Region($Cut, $p[0], [int]$p[1], [int]$p[2], [int]$p[3], [int]$p[4]) }
}

