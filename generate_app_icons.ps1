Add-Type -AssemblyName System.Drawing

function Generate-MyTeamsIcon([int]$size, [string]$outputPath, [bool]$transparentBg = $false) {
    $bmp = New-Object System.Drawing.Bitmap $size, $size
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $g.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAliasGridFit

    if ($transparentBg) {
        $g.Clear([System.Drawing.Color]::Transparent)
    } else {
        $g.Clear([System.Drawing.Color]::FromArgb(255, 57, 73, 171)) # #3949AB
    }

    # Draw rounded rectangle background with gradient
    $rect = New-Object System.Drawing.RectangleF 0, 0, $size, $size
    $color1 = [System.Drawing.Color]::FromArgb(255, 40, 53, 147) # #283593
    $color2 = [System.Drawing.Color]::FromArgb(255, 92, 107, 192) # #5C6BC0
    $gradientBrush = New-Object System.Drawing.Drawing2D.LinearGradientBrush $rect, $color1, $color2, 45.0
    
    # Corner radius ~ 22%
    $corner = $size * 0.22
    $path = New-Object System.Drawing.Drawing2D.GraphicsPath
    $path.AddArc(0, 0, $corner * 2, $corner * 2, 180, 90)
    $path.AddArc($size - $corner * 2, 0, $corner * 2, $corner * 2, 270, 90)
    $path.AddArc($size - $corner * 2, $size - $corner * 2, $corner * 2, $corner * 2, 0, 90)
    $path.AddArc(0, $size - $corner * 2, $corner * 2, $corner * 2, 90, 90)
    $path.CloseFigure()

    $g.FillPath($gradientBrush, $path)

    # Soft glowing circle in background
    $glowRect = New-Object System.Drawing.RectangleF ($size * 0.15), ($size * 0.15), ($size * 0.7), ($size * 0.7)
    $glowColor = [System.Drawing.Color]::FromArgb(40, 255, 255, 255)
    $glowBrush = New-Object System.Drawing.SolidBrush $glowColor
    $g.FillEllipse($glowBrush, $glowRect)

    # Draw Enterprise Building / Teams Collaboration Icon in pure white
    $whiteBrush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::White)
    $accentBrush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(255, 255, 215, 0)) # Gold accent
    $pen = New-Object System.Drawing.Pen ([System.Drawing.Color]::White), ($size * 0.04)
    $pen.StartCap = [System.Drawing.Drawing2D.LineCap]::Round
    $pen.EndCap = [System.Drawing.Drawing2D.LineCap]::Round

    # Central Main Building / Monolith
    $bWidth = $size * 0.38
    $bHeight = $size * 0.44
    $bLeft = ($size - $bWidth) / 2
    $bTop = $size * 0.26
    $bRadius = $size * 0.04

    $bPath = New-Object System.Drawing.Drawing2D.GraphicsPath
    $bPath.AddArc($bLeft, $bTop, $bRadius * 2, $bRadius * 2, 180, 90)
    $bPath.AddArc($bLeft + $bWidth - $bRadius * 2, $bTop, $bRadius * 2, $bRadius * 2, 270, 90)
    $bPath.AddLine($bLeft + $bWidth, $bTop + $bHeight, $bLeft, $bTop + $bHeight)
    $bPath.CloseFigure()
    $g.FillPath($whiteBrush, $bPath)

    # Left Wing Building
    $lWidth = $size * 0.16
    $lHeight = $size * 0.30
    $lLeft = $bLeft - $lWidth + ($size * 0.02)
    $lTop = $bTop + ($size * 0.14)
    $lRadius = $size * 0.03

    $lPath = New-Object System.Drawing.Drawing2D.GraphicsPath
    $lPath.AddArc($lLeft, $lTop, $lRadius * 2, $lRadius * 2, 180, 90)
    $lPath.AddArc($lLeft + $lWidth - $lRadius * 2, $lTop, $lRadius * 2, $lRadius * 2, 270, 90)
    $lPath.AddLine($lLeft + $lWidth, $lTop + $lHeight, $lLeft, $lTop + $lHeight)
    $lPath.CloseFigure()
    $lBrush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(210, 255, 255, 255))
    $g.FillPath($lBrush, $lPath)

    # Right Wing Building
    $rWidth = $size * 0.16
    $rHeight = $size * 0.30
    $rLeft = $bLeft + $bWidth - ($size * 0.02)
    $rTop = $bTop + ($size * 0.14)
    $rRadius = $size * 0.03

    $rPath = New-Object System.Drawing.Drawing2D.GraphicsPath
    $rPath.AddArc($rLeft, $rTop, $rRadius * 2, $rRadius * 2, 180, 90)
    $rPath.AddArc($rLeft + $rWidth - $rRadius * 2, $rTop, $rRadius * 2, $rRadius * 2, 270, 90)
    $rPath.AddLine($rLeft + $rWidth, $rTop + $rHeight, $rLeft, $rTop + $rHeight)
    $rPath.CloseFigure()
    $g.FillPath($lBrush, $rPath)

    # Windows on Central Building (Cutouts / Indigo color)
    $wBrush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(255, 57, 73, 171))
    $winSize = $size * 0.05
    $winGapX = $size * 0.04
    $winGapY = $size * 0.04
    $startY = $bTop + ($size * 0.06)

    for ($row = 0; $row -lt 3; $row++) {
        for ($col = 0; $col -lt 2; $col++) {
            $wx = $bLeft + ($size * 0.08) + ($col * ($winSize + $winGapX * 1.5))
            $wy = $startY + ($row * ($winSize + $winGapY))
            $wRect = New-Object System.Drawing.RectangleF $wx, $wy, $winSize, $winSize
            $g.FillRectangle($wBrush, $wRect)
        }
    }

    # Central Entrance Door
    $doorW = $size * 0.08
    $doorH = $size * 0.10
    $doorX = ($size - $doorW) / 2
    $doorY = $bTop + $bHeight - $doorH
    $doorRect = New-Object System.Drawing.RectangleF $doorX, $doorY, $doorW, $doorH
    $g.FillRectangle($wBrush, $doorRect)

    # Base Foundation Line
    $basePen = New-Object System.Drawing.Pen ([System.Drawing.Color]::White), ($size * 0.04)
    $basePen.StartCap = [System.Drawing.Drawing2D.LineCap]::Round
    $basePen.EndCap = [System.Drawing.Drawing2D.LineCap]::Round
    $g.DrawLine($basePen, ($size * 0.18), ($bTop + $bHeight + ($size * 0.02)), ($size * 0.82), ($bTop + $bHeight + ($size * 0.02)))

    # Star / Crown above building for achievement
    $starSize = $size * 0.055
    $starCenter = New-Object System.Drawing.PointF ($size * 0.5), ($size * 0.19)
    $starPath = New-Object System.Drawing.Drawing2D.GraphicsPath
    # 4-point diamond star
    $starPath.AddPolygon(@(
        (New-Object System.Drawing.PointF ($starCenter.X), ($starCenter.Y - $starSize)),
        (New-Object System.Drawing.PointF ($starCenter.X + $starSize * 0.35), ($starCenter.Y - $starSize * 0.35)),
        (New-Object System.Drawing.PointF ($starCenter.X + $starSize), ($starCenter.Y)),
        (New-Object System.Drawing.PointF ($starCenter.X + $starSize * 0.35), ($starCenter.Y + $starSize * 0.35)),
        (New-Object System.Drawing.PointF ($starCenter.X), ($starCenter.Y + $starSize)),
        (New-Object System.Drawing.PointF ($starCenter.X - $starSize * 0.35), ($starCenter.Y + $starSize * 0.35)),
        (New-Object System.Drawing.PointF ($starCenter.X - $starSize), ($starCenter.Y)),
        (New-Object System.Drawing.PointF ($starCenter.X - $starSize * 0.35), ($starCenter.Y - $starSize * 0.35))
    ))
    $g.FillPath($accentBrush, $starPath)

    # Save to path
    $dir = [System.IO.Path]::GetDirectoryName($outputPath)
    if (-not (Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }
    $bmp.Save($outputPath, [System.Drawing.Imaging.ImageFormat]::Png)
    $g.Dispose()
    $bmp.Dispose()
    Write-Host "Generated: $outputPath ($size x $size)"
}

# Android Mipmap densities
Generate-MyTeamsIcon 48 "android\app\src\main\res\mipmap-mdpi\ic_launcher.png"
Generate-MyTeamsIcon 72 "android\app\src\main\res\mipmap-hdpi\ic_launcher.png"
Generate-MyTeamsIcon 96 "android\app\src\main\res\mipmap-xhdpi\ic_launcher.png"
Generate-MyTeamsIcon 144 "android\app\src\main\res\mipmap-xxhdpi\ic_launcher.png"
Generate-MyTeamsIcon 192 "android\app\src\main\res\mipmap-xxxhdpi\ic_launcher.png"

# Master high-res icon in assets
Generate-MyTeamsIcon 1024 "assets\icon\app_icon.png"

# Web icons
Generate-MyTeamsIcon 32 "web\favicon.png"
Generate-MyTeamsIcon 192 "web\icons\Icon-192.png"
Generate-MyTeamsIcon 512 "web\icons\Icon-512.png"

# iOS App Icons
Generate-MyTeamsIcon 1024 "ios\Runner\Assets.xcassets\AppIcon.appiconset\Icon-App-1024x1024@1x.png"
Generate-MyTeamsIcon 20 "ios\Runner\Assets.xcassets\AppIcon.appiconset\Icon-App-20x20@1x.png"
Generate-MyTeamsIcon 40 "ios\Runner\Assets.xcassets\AppIcon.appiconset\Icon-App-20x20@2x.png"
Generate-MyTeamsIcon 60 "ios\Runner\Assets.xcassets\AppIcon.appiconset\Icon-App-20x20@3x.png"
Generate-MyTeamsIcon 29 "ios\Runner\Assets.xcassets\AppIcon.appiconset\Icon-App-29x29@1x.png"
Generate-MyTeamsIcon 58 "ios\Runner\Assets.xcassets\AppIcon.appiconset\Icon-App-29x29@2x.png"
Generate-MyTeamsIcon 87 "ios\Runner\Assets.xcassets\AppIcon.appiconset\Icon-App-29x29@3x.png"
Generate-MyTeamsIcon 40 "ios\Runner\Assets.xcassets\AppIcon.appiconset\Icon-App-40x40@1x.png"
Generate-MyTeamsIcon 80 "ios\Runner\Assets.xcassets\AppIcon.appiconset\Icon-App-40x40@2x.png"
Generate-MyTeamsIcon 120 "ios\Runner\Assets.xcassets\AppIcon.appiconset\Icon-App-40x40@3x.png"
Generate-MyTeamsIcon 120 "ios\Runner\Assets.xcassets\AppIcon.appiconset\Icon-App-60x60@2x.png"
Generate-MyTeamsIcon 180 "ios\Runner\Assets.xcassets\AppIcon.appiconset\Icon-App-60x60@3x.png"
Generate-MyTeamsIcon 76 "ios\Runner\Assets.xcassets\AppIcon.appiconset\Icon-App-76x76@1x.png"
Generate-MyTeamsIcon 152 "ios\Runner\Assets.xcassets\AppIcon.appiconset\Icon-App-76x76@2x.png"
Generate-MyTeamsIcon 167 "ios\Runner\Assets.xcassets\AppIcon.appiconset\Icon-App-83.5x83.5@2x.png"
