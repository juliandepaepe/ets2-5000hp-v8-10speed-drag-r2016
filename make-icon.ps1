<#
.SYNOPSIS
    Produces the two images the mod needs, from any source picture.

.DESCRIPTION
    Both targets have hard requirements and both must be JPEG:

      src\mod_icon.jpg            276 x 162  - in-game Mod Manager icon.
                                               The size is exact; the game
                                               shows nothing if it is wrong.
      dist\workshop_preview.jpg   640 x 360  - Steam Workshop preview image,
                                               max 1 MB.

    The source is scaled to cover the target and then centre-cropped, so the
    aspect change (16:9 vs 276:162) costs a few pixels off the sides rather
    than stretching the picture.

    Keep this file pure ASCII - Windows PowerShell 5.1 reads .ps1 as ANSI.

.EXAMPLE
    .\make-icon.ps1 -Source "C:\Users\REDICAT\Desktop\Capture_640x360.jpg"
    .\make-icon.ps1 -Source "shot.png" -IconOnly
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$Source,

    [switch]$IconOnly
)

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing

$Root = Split-Path -Parent $MyInvocation.MyCommand.Path
if (-not (Test-Path $Source)) { throw "Source image not found: $Source" }

function Convert-Cover {
    param([string]$In, [string]$Out, [int]$W, [int]$H, [int]$Quality = 90)

    $src = [System.Drawing.Image]::FromFile((Resolve-Path $In))
    try {
        # Scale to cover, then centre-crop the overflow.
        $scale = [math]::Max($W / $src.Width, $H / $src.Height)
        $sw    = [int][math]::Ceiling($src.Width  * $scale)
        $sh    = [int][math]::Ceiling($src.Height * $scale)
        $ox    = [int](($sw - $W) / 2)
        $oy    = [int](($sh - $H) / 2)

        $bmp = New-Object System.Drawing.Bitmap($W, $H)
        $g   = [System.Drawing.Graphics]::FromImage($bmp)
        try {
            $g.InterpolationMode  = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
            $g.PixelOffsetMode    = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
            $g.SmoothingMode      = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
            $g.DrawImage($src, -$ox, -$oy, $sw, $sh)
        }
        finally { $g.Dispose() }

        # Explicit JPEG encoder so quality is controlled rather than defaulted.
        $codec  = [System.Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() |
                  Where-Object { $_.MimeType -eq 'image/jpeg' }
        $params = New-Object System.Drawing.Imaging.EncoderParameters(1)
        $params.Param[0] = New-Object System.Drawing.Imaging.EncoderParameter(
            [System.Drawing.Imaging.Encoder]::Quality, [int]$Quality)

        $dir = Split-Path -Parent $Out
        if ($dir -and -not (Test-Path $dir)) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }
        if (Test-Path $Out) { Remove-Item $Out -Force }

        $bmp.Save($Out, $codec, $params)
        $bmp.Dispose()

        $kb = [math]::Round((Get-Item $Out).Length / 1KB, 1)
        Write-Host ("  {0}  ->  {1} x {2}, {3} KB" -f (Split-Path $Out -Leaf), $W, $H, $kb) -ForegroundColor Green
    }
    finally { $src.Dispose() }
}

$si = [System.Drawing.Image]::FromFile((Resolve-Path $Source))
Write-Host ("source: {0} ({1} x {2})" -f (Split-Path $Source -Leaf), $si.Width, $si.Height) -ForegroundColor DarkGray
$si.Dispose()

Convert-Cover -In $Source -Out (Join-Path $Root 'src\mod_icon.jpg') -W 276 -H 162

if (-not $IconOnly) {
    Convert-Cover -In $Source -Out (Join-Path $Root 'dist\workshop_preview.jpg') -W 640 -H 360
    Write-Host ""
    Write-Host "Point the uploader's Preview image field at:" -ForegroundColor Cyan
    Write-Host ("  " + (Join-Path $Root 'dist\workshop_preview.jpg')) -ForegroundColor Cyan
}
