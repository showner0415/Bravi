param([string]$Count = '', [string]$Iou = '', [string]$Box = '')
# 계획 026 결정 235: 한 색 실루엣 PNG의 파랑(칼 팔)·빨강(머리) 화소를 센다. 가장자리의 섞인 화소는 갈래에 들지 않는다.
# -Count "a.png;b.png"  -> count,<파일>,blue,red
# -Iou "a.png,b.png;..." -> iou,<파일1>,<파일2>,<값>   (파랑 마스크의 교집합 ÷ 합집합)
# -Box "a.png,x0,y0,x1,y1;..." -> box,<파일>,x0,y0,x1,y1,blue
Add-Type -AssemblyName System.Drawing
if (-not ('Sil026' -as [type])) {
Add-Type -ReferencedAssemblies System.Drawing -TypeDefinition @'
using System; using System.Drawing; using System.Drawing.Imaging; using System.Runtime.InteropServices;
public static class Sil026 {
  // 0 = 다른 것, 1 = 파랑(B >= 160, R <= 90, G <= 90), 2 = 빨강(R >= 160, G <= 90, B <= 90)
  public static byte[] Classes(string path, out int w, out int h) {
    var bm = new Bitmap(path); w = bm.Width; h = bm.Height;
    var d = bm.LockBits(new Rectangle(0, 0, w, h), ImageLockMode.ReadOnly, PixelFormat.Format32bppArgb);
    int st = d.Stride; var px = new byte[st * h]; Marshal.Copy(d.Scan0, px, 0, px.Length); bm.UnlockBits(d); bm.Dispose();
    var c = new byte[w * h];
    for (int y = 0; y < h; y++) for (int x = 0; x < w; x++) {
      int i = y * st + x * 4; int b = px[i], g = px[i + 1], r = px[i + 2];
      if (b >= 160 && r <= 90 && g <= 90) c[y * w + x] = 1; else if (r >= 160 && g <= 90 && b <= 90) c[y * w + x] = 2;
    }
    return c;
  }
  public static string Count(string path) {
    int w, h; var c = Classes(path, out w, out h); long bl = 0, rd = 0;
    foreach (var v in c) { if (v == 1) bl++; else if (v == 2) rd++; }
    return bl + "," + rd;
  }
  public static string Iou(string a, string b) {
    int w1, h1, w2, h2; var c1 = Classes(a, out w1, out h1); var c2 = Classes(b, out w2, out h2);
    if (w1 != w2 || h1 != h2) return "size-mismatch";
    long inter = 0, uni = 0;
    for (int i = 0; i < c1.Length; i++) { bool p = c1[i] == 1, q = c2[i] == 1; if (p && q) inter++; if (p || q) uni++; }
    return uni == 0 ? "0.000" : ((double)inter / uni).ToString("0.000");
  }
  public static long Box(string path, int x0, int y0, int x1, int y1) {
    int w, h; var c = Classes(path, out w, out h); long n = 0;
    for (int y = Math.Max(0, y0); y <= Math.Min(h - 1, y1); y++) for (int x = Math.Max(0, x0); x <= Math.Min(w - 1, x1); x++) if (c[y * w + x] == 1) n++;
    return n;
  }
}
'@
}
foreach ($f in ($Count.Split(';') | Where-Object { $_ })) { "count,$([IO.Path]::GetFileName($f)),$([Sil026]::Count($f))" }
foreach ($pr in ($Iou.Split(';') | Where-Object { $_ })) { $p = $pr.Split(','); "iou,$([IO.Path]::GetFileName($p[0])),$([IO.Path]::GetFileName($p[1])),$([Sil026]::Iou($p[0], $p[1]))" }
foreach ($bx in ($Box.Split(';') | Where-Object { $_ })) { $p = $bx.Split(','); "box,$([IO.Path]::GetFileName($p[0])),$($p[1]),$($p[2]),$($p[3]),$($p[4]),$([Sil026]::Box($p[0], [int]$p[1], [int]$p[2], [int]$p[3], [int]$p[4]))" }
