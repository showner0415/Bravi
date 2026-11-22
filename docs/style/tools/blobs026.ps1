param([string]$Img, [int]$Min = 500)
# 계획 026 판정 A-1b: 손질본(바탕을 지운 PNG)의 alpha >= 128 화소를 8방향으로 이어 덩이를 센다.
# 내는 줄: blob,<n>,<x0>,<y0>,<x1>,<y1>,<px> (Min 화소 이상인 덩이만, 큰 차례), 끝에 blobs,<수>
Add-Type -AssemblyName System.Drawing
if (-not ('Blobs026' -as [type])) {
Add-Type -ReferencedAssemblies System.Drawing -TypeDefinition @'
using System; using System.Drawing; using System.Drawing.Imaging; using System.Collections.Generic; using System.Runtime.InteropServices;
public static class Blobs026 {
  public static List<int[]> Find(string path, int min) {
    var bm = new Bitmap(path); int w = bm.Width, h = bm.Height;
    var d = bm.LockBits(new Rectangle(0, 0, w, h), ImageLockMode.ReadOnly, PixelFormat.Format32bppArgb);
    int st = d.Stride; var px = new byte[st * h]; Marshal.Copy(d.Scan0, px, 0, px.Length); bm.UnlockBits(d); bm.Dispose();
    var seen = new bool[w * h]; var outList = new List<int[]>(); var stack = new Stack<int>();
    for (int s = 0; s < w * h; s++) {
      if (seen[s] || px[(s / w) * st + (s % w) * 4 + 3] < 128) continue;
      int x0 = w, y0 = h, x1 = -1, y1 = -1, n = 0; seen[s] = true; stack.Push(s);
      while (stack.Count > 0) {
        int c = stack.Pop(), cx = c % w, cy = c / w; n++;
        if (cx < x0) x0 = cx; if (cx > x1) x1 = cx; if (cy < y0) y0 = cy; if (cy > y1) y1 = cy;
        for (int dy = -1; dy <= 1; dy++) for (int dx = -1; dx <= 1; dx++) {
          int nx = cx + dx, ny = cy + dy; if (nx < 0 || ny < 0 || nx >= w || ny >= h) continue;
          int k = ny * w + nx; if (seen[k] || px[ny * st + nx * 4 + 3] < 128) continue; seen[k] = true; stack.Push(k);
        }
      }
      if (n >= min) outList.Add(new int[] { x0, y0, x1, y1, n });
    }
    outList.Sort((a, b) => b[4].CompareTo(a[4]));
    return outList;
  }
}
'@
}
$list = [Blobs026]::Find($Img, $Min); $i = 0
foreach ($b in $list) { $i++; "blob,$i,$($b[0]),$($b[1]),$($b[2]),$($b[3]),$($b[4])" }
"blobs,$($list.Count)"
