param([string]$Off, [string]$On, [string]$Sig = '#4D80F2')
# Plan 030 decision 271 (bible 13.6 S3): every pixel of an off/on tint pair against the shader rule (opponent_part.gdshader).
# PASS: changed pixels matching the rule >= 97%, dark pixels (Y < 0.20) changed <= 1% (provisional thresholds; 029: 98.7%, 23 px). ASCII only.
Add-Type -AssemblyName System.Drawing
if (-not ('PixRule' -as [type])) {
Add-Type -ReferencedAssemblies System.Drawing -TypeDefinition @'
using System; using System.Drawing; using System.Drawing.Imaging; using System.Runtime.InteropServices;
public static class PixRule {
  static byte[] L(string p, out int st, out int w, out int h) { var b = new Bitmap(p); w = b.Width; h = b.Height; var d = b.LockBits(new Rectangle(0,0,w,h), ImageLockMode.ReadOnly, PixelFormat.Format32bppArgb); st = d.Stride; var a = new byte[st*h]; Marshal.Copy(d.Scan0, a, 0, a.Length); b.UnlockBits(d); b.Dispose(); return a; }
  public static string Run(string off, string on, string sig) {
    int st, w, h, st2, w2, h2; var a = L(off, out st, out w, out h); var b = L(on, out st2, out w2, out h2);
    double sr = Convert.ToInt32(sig.Substring(1, 2), 16), sg = Convert.ToInt32(sig.Substring(3, 2), 16), sb = Convert.ToInt32(sig.Substring(5, 2), 16);
    int changed = 0, match = 0, lineChanged = 0, lines = 0; int[] hist = new int[5];
    for (int y = 0; y < h; y++) for (int x = 0; x < w; x++) {
      int i = y*st + x*4; double r = a[i+2], g = a[i+1], bl = a[i];
      double Y = (0.2126*r + 0.7152*g + 0.0722*bl)/255.0;
      double d0 = Math.Max(Math.Abs(a[i+2]-b[i+2]), Math.Max(Math.Abs(a[i+1]-b[i+1]), Math.Abs(a[i]-b[i])));
      if (Y < 0.20) { lines++; if (d0 > 4) lineChanged++; }
      if (d0 <= 4) continue;
      changed++;
      double lw = Math.Min(1, Math.Max(0, (0.30 - Y)/0.08));
      double er = r + (sr - r)*0.8, eg = g + (sg - g)*0.8, eb = bl + (sb - bl)*0.8;
      er = er + (r - er)*lw; eg = eg + (g - eg)*lw; eb = eb + (bl - eb)*lw;
      double e = Math.Max(Math.Abs(er - b[i+2]), Math.Max(Math.Abs(eg - b[i+1]), Math.Abs(eb - b[i])));
      if (e <= 4) match++; else { int k = e <= 10 ? 0 : e <= 20 ? 1 : e <= 40 ? 2 : e <= 80 ? 3 : 4; hist[k]++; }
    }
    double rate = (double)match/Math.Max(1,changed), dark = (double)lineChanged/Math.Max(1,lines);
    return string.Format("changed {0}, match rule {1} ({2:P1}), mismatch by err 4-10:{3} 10-20:{4} 20-40:{5} 40-80:{6} >80:{7}; dark(Y<0.20) pixels {8}, of them changed {9} ({10:P2}) {11}",
      changed, match, rate, hist[0], hist[1], hist[2], hist[3], hist[4], lines, lineChanged, dark, rate >= 0.97 && dark <= 0.01 ? "PASS" : "FAIL");
  }
}
'@
}
[PixRule]::Run($Off, $On, $Sig)
