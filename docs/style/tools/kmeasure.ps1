# 계획 022 화풍 판정 K1~K5. 잴 자리는 호출하는 쪽이 화소로 넘긴다(파츠 좌표·높이 비율에서 셈).
Add-Type -AssemblyName System.Drawing
if (-not ('KM' -as [type])) {
Add-Type -ReferencedAssemblies System.Drawing -TypeDefinition @'
using System; using System.Drawing; using System.Drawing.Imaging; using System.Runtime.InteropServices; using System.Collections.Generic; using System.Linq; using System.Text;
public static class KM {
  static byte[] Load(string p, out int st, out int w, out int h) { var b = new Bitmap(p); w = b.Width; h = b.Height; var d = b.LockBits(new Rectangle(0, 0, w, h), ImageLockMode.ReadOnly, PixelFormat.Format32bppArgb); st = d.Stride; var a = new byte[st * h]; Marshal.Copy(d.Scan0, a, 0, a.Length); b.UnlockBits(d); b.Dispose(); return a; }
  static double Yv(byte[] px, int i) { return (0.2126 * px[i + 2] + 0.7152 * px[i + 1] + 0.0722 * px[i]) / 255.0; }
  // 무대: 1536x1024의 가운데 1536x864를 1280x720으로 맞춘다
  public static void Fit(string src, string dst) {
    var s = new Bitmap(src); var d = new Bitmap(1280, 720, PixelFormat.Format32bppArgb);
    using (var g = Graphics.FromImage(d)) { g.InterpolationMode = System.Drawing.Drawing2D.InterpolationMode.HighQualityBicubic; g.DrawImage(s, new Rectangle(0, 0, 1280, 720), new Rectangle(0, 80, 1536, 864), GraphicsUnit.Pixel); }
    d.Save(dst, ImageFormat.Png); d.Dispose(); s.Dispose();
  }
  // 알파 상자
  public static int[] Box(string p) { int st, w, h; var px = Load(p, out st, out w, out h); int x0 = w, y0 = h, x1 = 0, y1 = 0; for (int y = 0; y < h; y++) for (int x = 0; x < w; x++) if (px[y * st + x * 4 + 3] >= 128) { if (x < x0) x0 = x; if (x > x1) x1 = x; if (y < y0) y0 = y; if (y > y1) y1 = y; } return new[] { x0, y0, x1, y1 }; }
  // K1: 선 화소(Y < 0.22)의 가운데 RGB. rects는 "x0,y0,x1,y1;..."
  public static string K1(string p, string rects, bool alpha) {
    int st, w, h; var px = Load(p, out st, out w, out h); var R = new List<int>(); var G = new List<int>(); var B = new List<int>();
    foreach (var r in rects.Split(';')) { var v = r.Split(',').Select(int.Parse).ToArray(); for (int y = Math.Max(0, v[1]); y < Math.Min(h, v[3]); y++) for (int x = Math.Max(0, v[0]); x < Math.Min(w, v[2]); x++) { int i = y * st + x * 4; if (alpha && px[i + 3] < 250) continue; if (Yv(px, i) >= 0.22) continue; R.Add(px[i + 2]); G.Add(px[i + 1]); B.Add(px[i]); } }
    if (R.Count == 0) return "K1 none"; R.Sort(); G.Sort(); B.Sort(); int r0 = R[R.Count / 2], g0 = G[G.Count / 2], b0 = B[B.Count / 2];
    bool ok = Math.Abs(r0 - 59) <= 30 && Math.Abs(g0 - 42) <= 30 && Math.Abs(b0 - 30) <= 30 && r0 - b0 >= 5;
    return string.Format("K1 median {0},{1},{2} n{3} {4}", r0, g0, b0, R.Count, ok ? "PASS" : "FAIL");
  }
  // K2: 점마다 바탕 쪽에서 들어가 Y < 0.22가 처음 나온 곳부터 다시 Y >= 0.22(또는 알파 0)가 되는 곳 앞까지. pts는 "y,x,dir;..."
  public static string K2(string p, string pts, double unitPx) {
    int st, w, h; var px = Load(p, out st, out w, out h); var ws = new List<double>(); var sb = new StringBuilder();
    foreach (var t in pts.Split(';')) { var v = t.Split(',').Select(int.Parse).ToArray(); int y = v[0], x = v[1], dir = v[2], n = 0, steps = 0;
      // 2화소 이하의 덩이는 선이 아니라 안티에일리어싱 티끌로 보고 건너뛴다
      while (steps < 500) {
        while (x >= 0 && x < w && steps < 500) { int i = y * st + x * 4; if (px[i + 3] >= 128 && Yv(px, i) < 0.22) break; x += dir; steps++; }
        n = 0; while (x >= 0 && x < w) { int i = y * st + x * 4; if (px[i + 3] < 128 || Yv(px, i) >= 0.22) break; n++; x += dir; steps++; }
        if (n > 2 || x < 0 || x >= w) break;
      }
      ws.Add(n); sb.Append(n).Append(' '); }
    var pos = ws.Where(v => v > 0).ToList(); if (pos.Count == 0) return "K2 none";
    var srt = new List<double>(pos); srt.Sort(); double med = srt[srt.Count / 2];
    // K2'(023): 가운데 값의 0.6~1.6배를 벗어난 점(못 찾은 점 포함)이 3개 이하
    int outN = ws.Count(v => v <= 0 || v < 0.6 * med || v > 1.6 * med);
    return string.Format("K2 widths [{0}] max/min {1:F2} median {2} ({3:F1} units) zeros {4} | K2' out {5} {6}", sb.ToString().Trim(), pos.Max() / pos.Min(), med, med / unitPx, ws.Count - pos.Count, outN, outN <= 3 ? "PASS" : "FAIL");
  }
  // K3'(023): 부위(rect)마다 제자리·위·아래로 shift만큼 옮긴 상자 셋 안의 16x16 칸 가운데 가장 작은 sd
  public static string K3P(string p, string rects, int shift) {
    int st, w, h; var px = Load(p, out st, out w, out h); var sb = new StringBuilder(); bool all = true;
    foreach (var r in rects.Split(';')) { var v = r.Split(',').Select(int.Parse).ToArray(); double best = double.NaN;
      foreach (int dy in new[] { 0, -shift, shift }) { var cells = new List<double[]>();
        for (int cy = v[1] + dy; cy + 16 <= v[3] + dy; cy += 16) for (int cx = v[0]; cx + 16 <= v[2]; cx += 16) { double s = 0, s2 = 0; bool bad = cy < 0 || cy + 16 > h || cx < 0 || cx + 16 > w;
          for (int y = cy; y < cy + 16 && !bad; y++) for (int x = cx; x < cx + 16; x++) { int i = y * st + x * 4; if (px[i + 3] < 250) { bad = true; break; } double yy = Yv(px, i); if (yy < 0.22) { bad = true; break; } s += yy; s2 += yy * yy; }
          if (bad) continue; double m = s / 256, sd = Math.Sqrt(Math.Max(0, s2 / 256 - m * m)); cells.Add(new[] { m, sd }); }
        if (cells.Count == 0) continue;
        // 평평한 칸이 하나 있으면 된다: 칸이 주름·단추·칠과 그림자의 경계에 걸려도 판정이 흔들리지 않게
        double val = cells.Min(c => c[1]);
        if (double.IsNaN(best) || val < best) best = val; }
      sb.AppendFormat("{0:F4} ", best); if (double.IsNaN(best) || best > 0.025) all = false; }
    return string.Format("K3' min-sd per part [{0}] {1}", sb.ToString().Trim(), all ? "PASS" : "FAIL");
  }
  // K2 의뢰인: 알파 상자의 높이 비율 여섯에서 양옆(12점)
  public static string K2Box(string p, string fracs) {
    var b = Box(p); var sb = new StringBuilder();
    foreach (var f in fracs.Split(',').Select(double.Parse)) { int y = (int)(b[1] + f * (b[3] - b[1])); sb.AppendFormat("{0},{1},1;{0},{2},-1;", y, b[0] - 2, b[2] + 2); }
    return K2(p, sb.ToString().TrimEnd(';'), 1);
  }
  // K3: 16x16 칸(선·바탕 없는 칸)의 Y 표준편차. 칸 평균으로 밝은 무리(칠)·어두운 무리(그림자)를 갈라 가운데 값
  public static string K3(string p, string rects) {
    int st, w, h; var px = Load(p, out st, out w, out h); var cells = new List<double[]>();
    foreach (var r in rects.Split(';')) { var v = r.Split(',').Select(int.Parse).ToArray();
      for (int cy = v[1]; cy + 16 <= v[3]; cy += 16) for (int cx = v[0]; cx + 16 <= v[2]; cx += 16) { double s = 0, s2 = 0; bool bad = false;
        for (int y = cy; y < cy + 16 && !bad; y++) for (int x = cx; x < cx + 16; x++) { int i = y * st + x * 4; if (px[i + 3] < 250) { bad = true; break; } double yy = Yv(px, i); if (yy < 0.22) { bad = true; break; } s += yy; s2 += yy * yy; }
        if (bad) continue; double m = s / 256, sd = Math.Sqrt(Math.Max(0, s2 / 256 - m * m)); cells.Add(new[] { m, sd }); } }
    if (cells.Count == 0) return "K3 none";
    double lo = cells.Min(c => c[0]), hi = cells.Max(c => c[0]), mid = (lo + hi) / 2;
    Func<IEnumerable<double[]>, double> med = L => { var a = L.Select(c => c[1]).OrderBy(x => x).ToList(); return a.Count == 0 ? 0 : a[a.Count / 2]; };
    double mf = med(cells.Where(c => c[0] >= mid)), ms = med(cells.Where(c => c[0] < mid));
    return string.Format("K3 fill-median-sd {0:F4} shadow-median-sd {1:F4} cells {2} {3}", mf, ms, cells.Count, Math.Max(mf, ms) <= 0.025 ? "PASS" : "FAIL");
  }
  // K4: 칠(왼쪽)→그림자(오른쪽)으로 훑어 중간값을 처음 지나는 화소를 경계로, ±6 안의 사이 화소를 센다. segs는 "y,xa,xb;..."
  public static string K4(string p, string segs) {
    int st, w, h; var px = Load(p, out st, out w, out h); var sb = new StringBuilder(); int worst = -1;
    foreach (var t in segs.Split(';')) { var v = t.Split(',').Select(int.Parse).ToArray(); int y = v[0], xa = v[1], xb = v[2]; var Yl = new List<double>();
      for (int x = xa; x <= xb; x++) { int i = y * st + x * 4; Yl.Add(px[i + 3] < 128 ? double.NaN : Yv(px, i)); }
      int n = Yl.Count; var head = Yl.Take(Math.Max(3, n * 3 / 10)).Where(d => !double.IsNaN(d) && d >= 0.22).OrderBy(d => d).ToList(); var tail = Yl.Skip(n - Math.Max(3, n / 5)).Where(d => !double.IsNaN(d) && d >= 0.22).OrderBy(d => d).ToList();
      if (head.Count == 0 || tail.Count == 0) { sb.Append("[no-fill] "); continue; }
      double f0 = head[head.Count / 2], s0 = tail[tail.Count / 2], mid = (f0 + s0) / 2; int b = -1;
      for (int k = 0; k < n; k++) if (!double.IsNaN(Yl[k]) && Yl[k] <= mid) { b = k; break; }
      if (b < 11 || b + 11 >= n || f0 - s0 < 0.02) { sb.AppendFormat("[edge? f{0:F2} s{1:F2}] ", f0, s0); continue; }
      double fy = 0, sy = 0; for (int k = b - 11; k <= b - 7; k++) fy += Yl[k]; for (int k = b + 7; k <= b + 11; k++) sy += Yl[k]; fy /= 5; sy /= 5; double D = fy - sy;
      if (D < 0.04) { sb.AppendFormat("[D{0:F3}<0.04] ", D); continue; }
      int c = 0; for (int k = b - 6; k <= b + 6; k++) { double yy = Yl[k]; if (yy > sy + 0.2 * D && yy < fy - 0.2 * D) c++; }
      worst = Math.Max(worst, c); sb.AppendFormat("{0}(D{1:F3}) ", c, D); }
    return string.Format("K4 [{0}] worst {1} {2}", sb.ToString().Trim(), worst, worst < 0 ? "n/a" : worst <= 3 ? "PASS" : "FAIL");
  }
  // K5: 선 화소 = Y <= 0.45이면서 9x9 평균보다 0.08 이상 어두운 화소. rects가 비면 알파 안
  public static double K5(string p, string rects) {
    int st, w, h; var px = Load(p, out st, out w, out h); var Y = new double[w * h]; for (int y = 0; y < h; y++) for (int x = 0; x < w; x++) Y[y * w + x] = Yv(px, y * st + x * 4);
    var I = new double[(w + 1) * (h + 1)]; for (int y = 0; y < h; y++) { double row = 0; for (int x = 0; x < w; x++) { row += Y[y * w + x]; I[(y + 1) * (w + 1) + x + 1] = I[y * (w + 1) + x + 1] + row; } }
    Func<int, int, bool> inRegion; if (string.IsNullOrEmpty(rects)) inRegion = (x, y) => px[y * st + x * 4 + 3] >= 250;
    else { var R = rects.Split(';').Select(r => r.Split(',').Select(int.Parse).ToArray()).ToList(); inRegion = (x, y) => R.Any(v => x >= v[0] && x < v[2] && y >= v[1] && y < v[3]); }
    long area = 0, lines = 0;
    for (int y = 4; y < h - 4; y++) for (int x = 4; x < w - 4; x++) { if (!inRegion(x, y)) continue; area++; double yy = Y[y * w + x]; if (yy > 0.45) continue;
      double m = (I[(y + 5) * (w + 1) + x + 5] - I[(y - 4) * (w + 1) + x + 5] - I[(y + 5) * (w + 1) + x - 4] + I[(y - 4) * (w + 1) + x - 4]) / 81.0; if (m - yy >= 0.08) lines++; }
    return area == 0 ? 0 : (double)lines / area;
  }
}
'@
}
