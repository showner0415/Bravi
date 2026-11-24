param([string]$Src, [string]$Out, [int]$W = 450, [int]$H = 675)
# Plan 034 decision 346: shrink a cut-out client (transparent background, 1024x1536) to W x H for the game.
# Draws through premultiplied alpha (32bppPArgb) with high quality bicubic, so the cleared edge does not leave a grey rim.
# Writes a 32 bit RGBA PNG. Absolute paths only. ASCII only.
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
$s = New-Object System.Drawing.Bitmap $Src
$pa = New-Object System.Drawing.Bitmap $s.Width, $s.Height, ([System.Drawing.Imaging.PixelFormat]::Format32bppPArgb)
$g = [System.Drawing.Graphics]::FromImage($pa); $g.DrawImageUnscaled($s, 0, 0); $g.Dispose(); $s.Dispose()
$d = New-Object System.Drawing.Bitmap $W, $H, ([System.Drawing.Imaging.PixelFormat]::Format32bppPArgb)
$g = [System.Drawing.Graphics]::FromImage($d)
$g.CompositingMode = 'SourceCopy'; $g.InterpolationMode = 'HighQualityBicubic'; $g.PixelOffsetMode = 'HighQuality'
$attr = New-Object System.Drawing.Imaging.ImageAttributes; $attr.SetWrapMode([System.Drawing.Drawing2D.WrapMode]::TileFlipXY)
$g.DrawImage($pa, (New-Object System.Drawing.Rectangle 0, 0, $W, $H), 0, 0, $pa.Width, $pa.Height, [System.Drawing.GraphicsUnit]::Pixel, $attr)
$g.Dispose(); $pa.Dispose()
$o = $d.Clone((New-Object System.Drawing.Rectangle 0, 0, $W, $H), [System.Drawing.Imaging.PixelFormat]::Format32bppArgb); $d.Dispose()
$o.Save($Out, [System.Drawing.Imaging.ImageFormat]::Png)
$c = @($o.GetPixel(0, 0).A, $o.GetPixel($W - 1, 0).A, $o.GetPixel(0, $H - 1).A, $o.GetPixel($W - 1, $H - 1).A) -join ','
$o.Dispose()
Write-Output ("fitclient,{0},{1}x{2},corners alpha {3}" -f (Split-Path $Out -Leaf), $W, $H, $c)
