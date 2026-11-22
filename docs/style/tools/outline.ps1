param([string]$Png, [double]$Eps = 1.5)
# 계획 030 결정 269: 손 그림의 바깥 윤곽선 다각형을 자를 때 뽑는다(뷰가 실행 중에 화소를 읽지 않게).
# 알파 >= 128의 가장 큰 덩이(8방향)의 바깥 경계를 화소의 모서리를 따라 돈다(꼭짓점은 모서리의 정수 좌표. 화소 가운데를 잇지 않는다, T4).
# 그다음 Eps 화소로 줄인다(Douglas-Peucker). 내는 줄: outline,<점 수>,<넓이 줄이기 전>,<넓이 뒤>,<덩이 화소 수> 과 poly,<x,y;...>
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
if (-not ('Outline030' -as [type])) {
Add-Type -ReferencedAssemblies System.Drawing -TypeDefinition @'
using System; using System.Collections.Generic; using System.Drawing; using System.Drawing.Imaging; using System.Runtime.InteropServices; using System.Text;
public static class Outline030 {
  static double Area(List<int[]> p) { double s = 0; for (int i = 0; i < p.Count; i++) { var a = p[i]; var b = p[(i + 1) % p.Count]; s += (double)a[0] * b[1] - (double)b[0] * a[1]; } return Math.Abs(s) / 2; }
  static double Dist(int[] p, int[] a, int[] b) { double dx = b[0] - a[0], dy = b[1] - a[1]; double L = Math.Sqrt(dx * dx + dy * dy); if (L == 0) return Math.Sqrt(Math.Pow(p[0] - a[0], 2) + Math.Pow(p[1] - a[1], 2)); return Math.Abs(dy * p[0] - dx * p[1] + b[0] * a[1] - b[1] * a[0]) / L; }
  static void DP(List<int[]> p, int i0, int i1, double eps, bool[] keep) { double dm = 0; int im = -1; for (int i = i0 + 1; i < i1; i++) { double d = Dist(p[i], p[i0], p[i1]); if (d > dm) { dm = d; im = i; } } if (im >= 0 && dm > eps) { keep[im] = true; DP(p, i0, im, eps, keep); DP(p, im, i1, eps, keep); } }
  public static string Run(string path, double eps) {
    var bm = new Bitmap(path); int W = bm.Width, H = bm.Height; var d = bm.LockBits(new Rectangle(0, 0, W, H), ImageLockMode.ReadOnly, PixelFormat.Format32bppArgb);
    int st = d.Stride; var a = new byte[st * H]; Marshal.Copy(d.Scan0, a, 0, a.Length); bm.UnlockBits(d); bm.Dispose();
    var lab = new int[W * H]; int best = 0, bestN = 0, cur = 0; var q = new Queue<int>();
    for (int i = 0; i < W * H; i++) { if (lab[i] != 0 || a[(i / W) * st + (i % W) * 4 + 3] < 128) continue; cur++; int n = 0; lab[i] = cur; q.Enqueue(i);
      while (q.Count > 0) { int k = q.Dequeue(); n++; int x = k % W, y = k / W;
        for (int dy = -1; dy <= 1; dy++) for (int dx = -1; dx <= 1; dx++) { int nx = x + dx, ny = y + dy; if (nx < 0 || ny < 0 || nx >= W || ny >= H) continue; int j = ny * W + nx; if (lab[j] == 0 && a[ny * st + nx * 4 + 3] >= 128) { lab[j] = cur; q.Enqueue(j); } } }
      if (n > bestN) { bestN = n; best = cur; } }
    Func<int, int, bool> In = (x, y) => x >= 0 && y >= 0 && x < W && y < H && lab[y * W + x] == best;
    // 화소마다 덩이 밖과 맞닿은 변을 시계 방향의 모서리 변으로 모은다(시작 모서리 -> 끝 모서리)
    var next = new Dictionary<long, List<long>>(); Func<int, int, long> Key = (x, y) => (long)y * 100000 + x;
    Action<int, int, int, int> Add = (x0, y0, x1, y1) => { long k = Key(x0, y0); if (!next.ContainsKey(k)) next[k] = new List<long>(); next[k].Add(Key(x1, y1)); };
    for (int y = 0; y < H; y++) for (int x = 0; x < W; x++) { if (!In(x, y)) continue;
      if (!In(x, y - 1)) Add(x, y, x + 1, y); if (!In(x + 1, y)) Add(x + 1, y, x + 1, y + 1); if (!In(x, y + 1)) Add(x + 1, y + 1, x, y + 1); if (!In(x - 1, y)) Add(x, y + 1, x, y); }
    // 고리를 잇는다. 모서리에서 갈래가 둘이면(대각선으로만 닿은 곳) 오른쪽으로 꺾는 쪽을 고른다
    var loops = new List<List<int[]>>();
    while (next.Count > 0) { long start = -1; foreach (var kv in next) { start = kv.Key; break; }
      var loop = new List<int[]>(); long p0 = start, prev = -1; int guard = 0;
      while (guard++ < 4 * W * H + 8) { List<long> outs; if (!next.TryGetValue(p0, out outs) || outs.Count == 0) break;
        long pick = outs[0];
        if (outs.Count > 1 && prev >= 0) { int px = (int)(prev % 100000), py = (int)(prev / 100000), cx = (int)(p0 % 100000), cy = (int)(p0 / 100000); int ix = cx - px, iy = cy - py;
          foreach (var o in outs) { int ox = (int)(o % 100000) - cx, oy = (int)(o / 100000) - cy; if (ix * oy - iy * ox > 0) { pick = o; break; } } }
        outs.Remove(pick); if (outs.Count == 0) next.Remove(p0);
        loop.Add(new int[] { (int)(p0 % 100000), (int)(p0 / 100000) }); prev = p0; p0 = pick; if (p0 == start) break; }
      loops.Add(loop); }
    List<int[]> outer = null; double am = -1; foreach (var l in loops) { double ar = Area(l); if (ar > am) { am = ar; outer = l; } }
    // 곧은 줄의 가운데 꼭짓점을 뺀다
    var pts = new List<int[]>(); for (int i = 0; i < outer.Count; i++) { var p = outer[(i + outer.Count - 1) % outer.Count]; var c = outer[i]; var n = outer[(i + 1) % outer.Count];
      if ((c[0] - p[0]) * (n[1] - c[1]) - (c[1] - p[1]) * (n[0] - c[0]) != 0) pts.Add(c); }
    double area0 = Area(pts);
    // 닫힌 다각형 줄이기: 가장 먼 두 점으로 갈라 양쪽을 줄인다
    int ia = 0, ib = 0; double far = -1; for (int i = 0; i < pts.Count; i++) { double dd = Math.Pow(pts[i][0] - pts[0][0], 2) + Math.Pow(pts[i][1] - pts[0][1], 2); if (dd > far) { far = dd; ib = i; } }
    var keep = new bool[pts.Count]; keep[ia] = true; keep[ib] = true;
    var ring = new List<int[]>(pts); ring.Add(pts[0]); var keep2 = new bool[ring.Count]; keep2[0] = true; keep2[ib] = true; keep2[ring.Count - 1] = true;
    DP(ring, 0, ib, eps, keep2); DP(ring, ib, ring.Count - 1, eps, keep2);
    var simp = new List<int[]>(); for (int i = 0; i < ring.Count - 1; i++) if (keep2[i]) simp.Add(ring[i]);
    var sb = new StringBuilder(); sb.AppendLine(string.Format("outline,{0},{1},{2},{3},{4}", simp.Count, area0, Area(simp), bestN, pts.Count));
    sb.Append("poly,"); for (int i = 0; i < simp.Count; i++) { if (i > 0) sb.Append(';'); sb.Append(simp[i][0] + "," + simp[i][1]); } return sb.ToString();
  }
}
'@
}
[Outline030]::Run($Png, $Eps)
