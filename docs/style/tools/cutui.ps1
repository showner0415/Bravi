param([ValidateSet('paper', 'frame', 'button')][string]$Kind, [string]$Sheet, [string]$Out, [double]$Flatten = 1.0, [double]$Mean = 0, [double]$K = 0, [int]$Edge = 72, [int]$Tol = 28, [int]$Ring = 1, [switch]$OnPaper, [switch]$Plain, [string]$Tint = '', [switch]$Verify)
# Plan 033b decision 490: finish the three painted UI pictures. Absolute paths only. ASCII only. Prints one line of measured values.
#  -Kind paper : cut a 16:9 box out of the middle of the sheet (the generator gives 1717x916 -> 1628x916), then -Flatten f pushes the
#                relative luminance toward the mean (L' = mean + (L - mean) * f, hue kept, decision 491). Writes a 24 bit PNG.
#  -Kind frame : ink on white -> alpha (alpha = largest channel difference to white, colour solved back against white), cut to the ink box,
#                scale by K (default: outer line 4.5 source px = 3 screen px at density 1.5), then re-lay it as a 9 patch source
#                (corners 36x36 from the corners, edge strips -Edge long from the middle of each side, empty middle). Writes a 32 bit PNG.
#  -Kind button: erase the flat background colour (flood from the border, tolerance -Tol, -Ring pixels of fringe), cut to the box, scale by
#                K (default: height 84 = 56 screen px), -Flatten on the paper part only (pixels brighter than the ink). Writes a 32 bit PNG.
#  -Mean L     : (paper, button; optional) also move the mean of that same relative luminance to L (the pivot of the push), when the source is too dark to reach 0.68.
#  -OnPaper    : (frame) the ink is drawn on parchment, not on white: paper level per pixel = box blur (radius 24) of the luminance with ink pixels replaced by the median;
#                alpha = clamp((Lpaper - L - 0.08) / (Lpaper - 0.03 - 0.08)) so faint stains and grain stay 0; colour solved back against the paper colour. The rest is the white path.
#  -Tint RRGGBB: (paper; optional) after -Flatten/-Mean, add one offset per channel in sRGB so the mean colour lands on RRGGBB (grain contrast kept; plan 033b U2-1).
#  -Plain      : (frame; optional) keep only the outer line band (pixels closer than 5 source px to the edge of the 9 patch source); inner line and diamonds get alpha 0 (plan 033b U2-2, small panels).
#  -Verify     : runs the same arguments into a temporary file and compares its SHA256 with the existing -Out; makes nothing.
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
if (-not ('CutUi' -as [type])) {
Add-Type -ReferencedAssemblies System.Drawing -TypeDefinition @'
using System; using System.Collections.Generic; using System.Drawing; using System.Drawing.Drawing2D; using System.Drawing.Imaging; using System.Globalization; using System.Runtime.InteropServices;
public static class CutUi {
  public class Img { public int W, H; public byte[] P; }   // BGRA, compact rows
  static double[] lin = BuildLin();
  static double[] BuildLin() { var t = new double[256]; for (int i = 0; i < 256; i++) { double c = i / 255.0; t[i] = c <= 0.04045 ? c / 12.92 : Math.Pow((c + 0.055) / 1.055, 2.4); } return t; }
  static byte Enc(double v) { v = Math.Max(0, Math.Min(1, v)); double c = v <= 0.0031308 ? v * 12.92 : 1.055 * Math.Pow(v, 1 / 2.4) - 0.055; return (byte)Math.Round(c * 255); }
  static double Lum(byte r, byte g, byte b) { return 0.2126 * lin[r] + 0.7152 * lin[g] + 0.0722 * lin[b]; }
  static string F(double v, string f) { return v.ToString(f, CultureInfo.InvariantCulture); }

  static Img FromBitmap(Bitmap b) {
    var im = new Img(); im.W = b.Width; im.H = b.Height; im.P = new byte[im.W * im.H * 4];
    var d = b.LockBits(new Rectangle(0, 0, im.W, im.H), ImageLockMode.ReadOnly, PixelFormat.Format32bppArgb);
    for (int y = 0; y < im.H; y++) Marshal.Copy(IntPtr.Add(d.Scan0, y * d.Stride), im.P, y * im.W * 4, im.W * 4);
    b.UnlockBits(d); return im;
  }
  static Img Read(string path) {
    using (var b0 = new Bitmap(path)) using (var b = b0.Clone(new Rectangle(0, 0, b0.Width, b0.Height), PixelFormat.Format32bppArgb)) return FromBitmap(b);
  }
  static Bitmap ToBitmap(Img im) {
    var b = new Bitmap(im.W, im.H, PixelFormat.Format32bppArgb);
    var d = b.LockBits(new Rectangle(0, 0, im.W, im.H), ImageLockMode.WriteOnly, PixelFormat.Format32bppArgb);
    for (int y = 0; y < im.H; y++) Marshal.Copy(im.P, y * im.W * 4, IntPtr.Add(d.Scan0, y * d.Stride), im.W * 4);
    b.UnlockBits(d); return b;
  }
  static void Save(Img im, string path, bool alpha) {
    using (var b = ToBitmap(im)) {
      if (alpha) { b.Save(path, ImageFormat.Png); return; }
      using (var o = b.Clone(new Rectangle(0, 0, im.W, im.H), PixelFormat.Format24bppRgb)) o.Save(path, ImageFormat.Png);
    }
  }
  static Img Crop(Img s, int x0, int y0, int w, int h) {
    var o = new Img(); o.W = w; o.H = h; o.P = new byte[w * h * 4];
    for (int y = 0; y < h; y++) Array.Copy(s.P, ((y0 + y) * s.W + x0) * 4, o.P, y * w * 4, w * 4);
    return o;
  }
  // Scale through premultiplied alpha so the cleared edge leaves no coloured rim (same way as fitclient.ps1).
  static Img Scale(Img s, int nw, int nh) {
    using (var src = ToBitmap(s)) using (var pa = new Bitmap(s.W, s.H, PixelFormat.Format32bppPArgb)) {
      using (var g = Graphics.FromImage(pa)) { g.CompositingMode = CompositingMode.SourceCopy; g.DrawImage(src, new Rectangle(0, 0, s.W, s.H), 0, 0, s.W, s.H, GraphicsUnit.Pixel); }
      using (var d = new Bitmap(nw, nh, PixelFormat.Format32bppPArgb)) {
        using (var g = Graphics.FromImage(d)) {
          g.CompositingMode = CompositingMode.SourceCopy; g.InterpolationMode = InterpolationMode.HighQualityBicubic; g.PixelOffsetMode = PixelOffsetMode.HighQuality;
          var at = new ImageAttributes(); at.SetWrapMode(WrapMode.TileFlipXY);
          g.DrawImage(pa, new Rectangle(0, 0, nw, nh), 0, 0, s.W, s.H, GraphicsUnit.Pixel, at);
        }
        using (var o = d.Clone(new Rectangle(0, 0, nw, nh), PixelFormat.Format32bppArgb)) return FromBitmap(o);
      }
    }
  }

  // ---- luminance stats over the "paper" pixels (opaque, and for the button brighter than the ink) ----
  static double Weight(double L, bool button) { if (!button) return 1; double t = Math.Max(0, Math.Min(1, (L - 0.2) / 0.2)); return t * t * (3 - 2 * t); }
  class St { public double mean, p5, r, g, b; public int n; }
  static St Stats(Img im, bool button, Rectangle? box) {
    var ls = new List<double>(); double sr = 0, sg = 0, sb = 0;
    for (int y = 0; y < im.H; y++) for (int x = 0; x < im.W; x++) {
      if (box.HasValue && !box.Value.Contains(x, y)) continue;
      int i = (y * im.W + x) * 4; if (im.P[i + 3] < 250) continue;
      double L = Lum(im.P[i + 2], im.P[i + 1], im.P[i]); if (Weight(L, button) < 0.5) continue;
      ls.Add(L); sr += im.P[i + 2]; sg += im.P[i + 1]; sb += im.P[i];
    }
    var s = new St(); s.n = ls.Count; if (s.n == 0) return s;
    double m = 0; foreach (var v in ls) m += v; s.mean = m / s.n; ls.Sort(); s.p5 = ls[(int)(0.05 * (s.n - 1))];
    s.r = sr / s.n; s.g = sg / s.n; s.b = sb / s.n; return s;
  }
  static void Squash(Img im, double f, double mean, double to, bool button) {
    if (f >= 1.0 && to == mean) return;
    for (int k = 0; k < im.W * im.H; k++) {
      int i = k * 4; if (im.P[i + 3] == 0) continue;
      double L = Lum(im.P[i + 2], im.P[i + 1], im.P[i]); double w = Weight(L, button); if (w <= 0 || L < 1e-6) continue;
      double Lp = L + w * ((to + (L - mean) * f) - L); double q = Lp / L;
      for (int c = 0; c < 3; c++) im.P[i + c] = Enc(lin[im.P[i + c]] * q);
    }
  }
  static string Tone(St pre, St post, double f) {
    double fmax = pre.p5 >= 0.62 ? 1.0 : (pre.mean > 0.62 ? (pre.mean - 0.62) / (pre.mean - pre.p5) : 0.0);
    string hex = string.Format("#{0:X2}{1:X2}{2:X2}", (int)Math.Round(post.r), (int)Math.Round(post.g), (int)Math.Round(post.b));
    int dmax = (int)Math.Round(Math.Max(Math.Abs(post.r - 233), Math.Max(Math.Abs(post.g - 216), Math.Abs(post.b - 180))));
    return string.Format("flatten {0},L mean {1} p5 {2} -> mean {3} p5 {4},colour {5} (max channel diff to E9D8B4 {6}),fmax {7} (ga {7} na {8} da {9})",
      F(f, "0.000"), F(pre.mean, "0.000"), F(pre.p5, "0.000"), F(post.mean, "0.000"), F(post.p5, "0.000"), hex, dmax, F(fmax, "0.000"), F(fmax * 0.7, "0.000"), F(fmax * 0.45, "0.000"));
  }

  // ---- paper ----
  public static string Paper(string sheet, string outp, double f, double to, string tint) {
    var im = Read(sheet); int cw = im.W, ch = im.H; int want = (int)Math.Round(im.H * 16.0 / 9.0);
    if (im.W >= want) cw = want; else ch = (int)Math.Round(im.W * 9.0 / 16.0);
    var c = Crop(im, (im.W - cw) / 2, (im.H - ch) / 2, cw, ch);
    var pre = Stats(c, false, null); Squash(c, f, pre.mean, to > 0 ? to : pre.mean, false); var post = Stats(c, false, null);
    if (!string.IsNullOrEmpty(tint)) { int tr = Convert.ToInt32(tint.Substring(0, 2), 16), tg = Convert.ToInt32(tint.Substring(2, 2), 16), tb = Convert.ToInt32(tint.Substring(4, 2), 16);
      double dr = tr - post.r, dg = tg - post.g, db = tb - post.b;
      for (int k = 0; k < c.W * c.H; k++) { int i = k * 4; c.P[i + 2] = (byte)Math.Max(0, Math.Min(255, Math.Round(c.P[i + 2] + dr))); c.P[i + 1] = (byte)Math.Max(0, Math.Min(255, Math.Round(c.P[i + 1] + dg))); c.P[i] = (byte)Math.Max(0, Math.Min(255, Math.Round(c.P[i] + db))); }
      post = Stats(c, false, null); }
    int bx = (int)(cw * 0.05), by = (int)(ch * 0.05); double se = 0, sc = 0; int ne = 0, nc = 0;
    for (int y = 0; y < ch; y++) for (int x = 0; x < cw; x++) { int i = (y * cw + x) * 4; double L = Lum(c.P[i + 2], c.P[i + 1], c.P[i]);
      if (x < bx || x >= cw - bx || y < by || y >= ch - by) { se += L; ne++; } else { sc += L; nc++; } }
    Save(c, outp, false);
    return string.Format("{0}x{1} from {2}x{3},{4},edge5% minus centre L {5}", cw, ch, im.W, im.H, Tone(pre, post, f), F(se / ne - sc / nc, "0.000"));
  }

  // ---- scans on the alpha channel (>= 26 counts as ink). A run is measured as sum of alpha / peak alpha, i.e. the width of a solid line ----
  static int A(Img im, int x, int y) { return im.P[(y * im.W + x) * 4 + 3]; }
  static double Run(Img im, int x, int y, int dx, int dy, out int len) {
    double sum = 0, peak = 0; len = 0;
    for (int sk = 0; sk < 24 && x >= 0 && y >= 0 && x < im.W && y < im.H && A(im, x, y) < 128; sk++) { x += dx; y += dy; }
    while (x >= 0 && y >= 0 && x < im.W && y < im.H && A(im, x, y) >= 8) { double a = A(im, x, y) / 255.0; sum += a; if (a > peak) peak = a; len++; x += dx; y += dy; }
    return peak > 0 ? sum / peak : 0;
  }

  static int RunDark(Img im, int x, int y, int dx, int dy) {
    int n = 0;
    while (x >= 0 && y >= 0 && x < im.W && y < im.H) { int i = (y * im.W + x) * 4; if (im.P[i + 3] < 128 || Lum(im.P[i + 2], im.P[i + 1], im.P[i]) >= 0.25) break; n++; x += dx; y += dy; }
    return n;
  }

  // paper level for -OnPaper: pm = linear median colour b,g,r in 0..2 and its luminance in 3 (index order matches the BGRA bytes)
  static double[] PaperLevel(Img im, out double[] pm) {
    int W = im.W, H = im.H, n = W * H; var Ls = new double[n]; var all = new List<double>(n);
    for (int p = 0; p < n; p++) { int i = p * 4; Ls[p] = Lum(im.P[i + 2], im.P[i + 1], im.P[i]); }
    var cb = new List<byte>[3]; for (int c = 0; c < 3; c++) cb[c] = new List<byte>(n);
    for (int p = 0; p < n; p++) for (int c = 0; c < 3; c++) cb[c].Add(im.P[p * 4 + c]);
    pm = new double[4]; for (int c = 0; c < 3; c++) { cb[c].Sort(); pm[c] = lin[cb[c][n / 2]]; }
    pm[3] = 0.0722 * pm[0] + 0.7152 * pm[1] + 0.2126 * pm[2];
    var cl = new double[n]; for (int p = 0; p < n; p++) cl[p] = Ls[p] > 0.6 * pm[3] ? Ls[p] : pm[3];
    int R = 24; var tmp = new double[n]; var o = new double[n];
    for (int y = 0; y < H; y++) { var cum = new double[W + 1]; for (int x = 0; x < W; x++) cum[x + 1] = cum[x] + cl[y * W + x];
      for (int x = 0; x < W; x++) { int a = Math.Max(0, x - R), b = Math.Min(W - 1, x + R); tmp[y * W + x] = (cum[b + 1] - cum[a]) / (b - a + 1); } }
    for (int x = 0; x < W; x++) { var cum = new double[H + 1]; for (int y = 0; y < H; y++) cum[y + 1] = cum[y] + tmp[y * W + x];
      for (int y = 0; y < H; y++) { int a = Math.Max(0, y - R), b = Math.Min(H - 1, y + R); o[y * W + x] = (cum[b + 1] - cum[a]) / (b - a + 1); } }
    return o;
  }

  // ---- frame ----
  public static string Frame(string sheet, string outp, double k, int edge, bool onPaper, bool plain) {
    var im = Read(sheet); int W = im.W, H = im.H;
    double[] lp = null; double[] pm = null;
    if (onPaper) { lp = PaperLevel(im, out pm); }
    for (int p = 0; p < W * H; p++) { int i = p * 4; int r = im.P[i + 2], g = im.P[i + 1], b = im.P[i];
      if (onPaper) {
        double L = Lum(im.P[i + 2], im.P[i + 1], im.P[i]); double Lp = lp[p]; double al = Math.Max(0, Math.Min(1, (Lp - L - 0.08) / (Lp - 0.03 - 0.08)));
        int ab = (int)Math.Round(al * 255); if (ab <= 6) { im.P[i] = im.P[i + 1] = im.P[i + 2] = im.P[i + 3] = 0; continue; }
        double q = Lp / pm[3]; byte[] o3 = new byte[3];
        for (int c = 0; c < 3; c++) { double pl = pm[c] * q; double px = lin[im.P[i + c]]; double v = (px - pl * (1 - al)) / al; o3[c] = Enc(v); }
        im.P[i] = o3[0]; im.P[i + 1] = o3[1]; im.P[i + 2] = o3[2]; im.P[i + 3] = (byte)ab; continue;
      }
      int a = Math.Max(255 - r, Math.Max(255 - g, 255 - b)); if (a <= 6) { im.P[i] = im.P[i + 1] = im.P[i + 2] = im.P[i + 3] = 0; continue; }
      double af = a / 255.0; im.P[i + 2] = (byte)Math.Max(0, Math.Min(255, Math.Round((r - 255 * (1 - af)) / af)));
      im.P[i + 1] = (byte)Math.Max(0, Math.Min(255, Math.Round((g - 255 * (1 - af)) / af))); im.P[i] = (byte)Math.Max(0, Math.Min(255, Math.Round((b - 255 * (1 - af)) / af))); im.P[i + 3] = (byte)a; }
    int x0 = W, y0 = H, x1 = -1, y1 = -1;
    for (int y = 0; y < H; y++) for (int x = 0; x < W; x++) if (A(im, x, y) >= (onPaper ? 128 : 26)) { if (x < x0) x0 = x; if (x > x1) x1 = x; if (y < y0) y0 = y; if (y > y1) y1 = y; }
    if (x1 < 0) throw new Exception("no ink found");
    var ink = Crop(im, x0, y0, x1 - x0 + 1, y1 - y0 + 1); int w0 = ink.W, h0 = ink.H; int ln;
    double t0 = (Run(ink, 0, h0 / 2, 1, 0, out ln) + Run(ink, w0 - 1, h0 / 2, -1, 0, out ln) + Run(ink, w0 / 2, 0, 0, 1, out ln) + Run(ink, w0 / 2, h0 - 1, 0, -1, out ln)) / 4.0;
    double kk = k > 0 ? k : 4.5 / t0;
    var s = Scale(ink, (int)Math.Round(w0 * kk), (int)Math.Round(h0 * kk)); int w1 = s.W, h1 = s.H; const int m = 36; const double dens = 1.5;
    if (w1 < 2 * m + edge || h1 < 2 * m + edge) throw new Exception("scaled ink " + w1 + "x" + h1 + " is smaller than the 9 patch source");
    // measures on the scaled ink, in screen pixels (source / 1.5)
    int l1, l2, l3, l4; double ot = (Run(s, 0, h1 / 2, 1, 0, out l1) + Run(s, w1 - 1, h1 / 2, -1, 0, out l2) + Run(s, w1 / 2, 0, 0, 1, out l3) + Run(s, w1 / 2, h1 - 1, 0, -1, out l4)) / 4.0;
    int sx = l1; while (sx < w1 && A(s, sx, h1 / 2) < 26) sx++; int l5; double iw = Run(s, sx, h1 / 2, 1, 0, out l5); double ic = sx + l5 / 2.0;
    int dn; Run(s, (int)Math.Round(ic), (int)Math.Round(ic), 1, 1, out dn);
    int depth = 0; for (int x = 0; x < w1 / 4; x++) if (A(s, x, h1 / 2) >= 26) depth = x + 1;
    double sa = 0; int na = 0; for (int y = h1 / 10; y < h1 - h1 / 10; y++) for (int x = w1 / 10; x < w1 - w1 / 10; x++) { sa += A(s, x, y) / 255.0; na++; }
    // re-lay: corners from the corners, edge strips from the middle of each side, empty middle
    int S = 2 * m + edge; var o = new Img(); o.W = S; o.H = S; o.P = new byte[S * S * 4];
    Action<int, int, int, int, int, int> blit = (sx0, sy0, dx0, dy0, bw, bh) => { for (int y = 0; y < bh; y++) Array.Copy(s.P, ((sy0 + y) * w1 + sx0) * 4, o.P, ((dy0 + y) * S + dx0) * 4, bw * 4); };
    blit(0, 0, 0, 0, m, m); blit(w1 - m, 0, S - m, 0, m, m); blit(0, h1 - m, 0, S - m, m, m); blit(w1 - m, h1 - m, S - m, S - m, m, m);
    blit((w1 - edge) / 2, 0, m, 0, edge, m); blit((w1 - edge) / 2, h1 - m, m, S - m, edge, m); blit(0, (h1 - edge) / 2, 0, m, m, edge); blit(w1 - m, (h1 - edge) / 2, S - m, m, m, edge);
    double oc = 0; for (int y = m; y < S - m; y++) for (int x = m; x < S - m; x++) oc += o.P[(y * S + x) * 4 + 3];
    if (plain) { for (int y = 0; y < S; y++) for (int x = 0; x < S; x++) { if (Math.Min(Math.Min(x, y), Math.Min(S - 1 - x, S - 1 - y)) >= 5) { int i = (y * S + x) * 4; o.P[i] = o.P[i + 1] = o.P[i + 2] = o.P[i + 3] = 0; } } }
    Save(o, outp, true);
    return string.Format("ink {0}x{1},outer line {2} source px,K {3},scaled {4}x{5},outer line {6} screen,inner line offset {7} width {8} screen,diamond radius about {9} screen,ink depth on a side {10} screen,centre alpha mean {11},out {12}x{12} centre alpha {13}",
      w0, h0, F(t0, "0.00"), F(kk, "0.0000"), w1, h1, F(ot / dens, "0.00"), F(ic / dens, "0.00"), F(iw / dens, "0.00"), F(2.0 * dn / dens, "0.0"), F(depth / dens, "0.0"), F(sa / na, "0.0000"), S, F(oc, "0"));
  }

  // ---- button ----
  public static string Button(string sheet, string outp, double f, double to, double k, int tol, int ring) {
    var im = Read(sheet); int W = im.W, H = im.H;
    var rs = new List<int>(); var gs = new List<int>(); var bs = new List<int>();
    Action<int, int> add = (x, y) => { int i = (y * W + x) * 4; bs.Add(im.P[i]); gs.Add(im.P[i + 1]); rs.Add(im.P[i + 2]); };
    for (int x = 0; x < W; x++) { add(x, 0); add(x, H - 1); } for (int y = 0; y < H; y++) { add(0, y); add(W - 1, y); }
    rs.Sort(); gs.Sort(); bs.Sort(); int R = rs[rs.Count / 2], G = gs[gs.Count / 2], B = bs[bs.Count / 2];
    var bg = new bool[W * H]; var q = new Queue<int>();
    Func<int, bool> near = p => { int i = p * 4; return Math.Abs(im.P[i + 2] - R) <= tol && Math.Abs(im.P[i + 1] - G) <= tol && Math.Abs(im.P[i] - B) <= tol; };
    Action<int> seed = p => { if (!bg[p] && near(p)) { bg[p] = true; q.Enqueue(p); } };
    for (int x = 0; x < W; x++) { seed(x); seed((H - 1) * W + x); } for (int y = 0; y < H; y++) { seed(y * W); seed(y * W + W - 1); }
    while (q.Count > 0) { int p = q.Dequeue(); int x = p % W, y = p / W; if (x > 0) seed(p - 1); if (x < W - 1) seed(p + 1); if (y > 0) seed(p - W); if (y < H - 1) seed(p + W); }
    for (int it = 0; it < ring; it++) { var add2 = new List<int>();
      for (int y = 1; y < H - 1; y++) for (int x = 1; x < W - 1; x++) { int p = y * W + x; if (!bg[p] && (bg[p - 1] || bg[p + 1] || bg[p - W] || bg[p + W])) add2.Add(p); }
      foreach (int p in add2) bg[p] = true; }
    int x0 = W, y0 = H, x1 = -1, y1 = -1;
    for (int p = 0; p < W * H; p++) { if (bg[p]) { im.P[p * 4 + 3] = 0; continue; } int x = p % W, y = p / W; if (x < x0) x0 = x; if (x > x1) x1 = x; if (y < y0) y0 = y; if (y > y1) y1 = y; }
    if (x1 < 0) throw new Exception("nothing left after erasing the background");
    var cut = Crop(im, x0, y0, x1 - x0 + 1, y1 - y0 + 1); int w0 = cut.W, h0 = cut.H;
    double kk = k > 0 ? k : 84.0 / h0; int nh = k > 0 ? (int)Math.Round(h0 * kk) : 84; int nw = (int)Math.Round(w0 * kk);
    string cs = A(cut, 0, 0) + "," + A(cut, w0 - 1, 0) + "," + A(cut, 0, h0 - 1) + "," + A(cut, w0 - 1, h0 - 1);
    var s = Scale(cut, nw, nh);
    var pre = Stats(s, true, null); Squash(s, f, pre.mean, to > 0 ? to : pre.mean, true); var post = Stats(s, true, null);
    Save(s, outp, true);
    const double dens = 1.5; int mx = nw / 2, my = nh / 2;
    int bt = RunDark(s, mx, 0, 0, 1); int sy = bt; while (sy < nh && A(s, mx, sy) >= 128 && RunDark(s, mx, sy, 0, 1) == 0) sy++; int iw = RunDark(s, mx, sy, 0, 1);
    int nx = 0; while (nx < nw && A(s, nx, my) < 128) nx++;    return string.Format("bg #{0:X2}{1:X2}{2:X2},box {3}x{4},K {5},out {6}x{7},corners alpha source {8} out {9},{10},{11},{12},top border {13} screen,inner line at {14} width {15} screen,notch depth {16} screen,cap suggestion {17} screen,band suggestion {18} screen,{19}",
      R, G, B, w0, h0, F(kk, "0.0000"), nw, nh, cs, A(s, 0, 0), A(s, nw - 1, 0), A(s, 0, nh - 1), A(s, nw - 1, nh - 1), F(bt / dens, "0.00"), F(sy / dens, "0.00"), F(iw / dens, "0.00"), F(nx / dens, "0.0"),
      F((nx + bt) / dens, "0.0"), F((sy + iw) / dens, "0.0"), Tone(pre, post, f));
  }
}
'@
}
function Invoke-CutUi([string]$Dest) {
  switch ($Kind) {
    'paper' { [CutUi]::Paper($Sheet, $Dest, $Flatten, $Mean, $Tint) }
    'frame' { [CutUi]::Frame($Sheet, $Dest, $K, $Edge, [bool]$OnPaper, [bool]$Plain) }
    'button' { [CutUi]::Button($Sheet, $Dest, $Flatten, $Mean, $K, $Tol, $Ring) }
  }
}
$name = [IO.Path]::GetFileName($Out)
if ($Verify) {
  $tmp = [IO.Path]::Combine([IO.Path]::GetTempPath(), 'cutui-verify-' + [Guid]::NewGuid().ToString('N') + '.png')
  try {
    $null = Invoke-CutUi $tmp
    $a = (Get-FileHash $tmp -Algorithm SHA256).Hash; $b = (Get-FileHash $Out -Algorithm SHA256).Hash
    "verify,$Kind,$name,$(if ($a -eq $b) { 'hash same' } else { 'hash DIFFERENT' }),$($b.Substring(0, 12))"
  } finally { Remove-Item $tmp -ErrorAction SilentlyContinue }
} else {
  New-Item -ItemType Directory -Force -Path (Split-Path $Out) | Out-Null
  "cutui,$Kind,$name,$(Invoke-CutUi $Out)"
}
