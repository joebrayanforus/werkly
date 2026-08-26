param(
  [Parameter(Mandatory = $true)]
  [string]$IllustrationPath
)

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing

$projectRoot = Split-Path -Parent $PSScriptRoot
$storeDir = Join-Path $projectRoot 'assets\store'
New-Item -ItemType Directory -Force -Path $storeDir | Out-Null

$poppinsRegular = Join-Path $projectRoot 'assets\fonts\Poppins-Regular.ttf'
$poppinsSemiBold = Join-Path $projectRoot 'assets\fonts\Poppins-SemiBold.ttf'
$fonts = New-Object System.Drawing.Text.PrivateFontCollection
$fonts.AddFontFile($poppinsRegular)
$fonts.AddFontFile($poppinsSemiBold)
$fontFamily = $fonts.Families[0]

function New-RoundedPath {
  param(
    [float]$X,
    [float]$Y,
    [float]$Width,
    [float]$Height,
    [float]$Radius
  )
  $diameter = $Radius * 2
  $path = New-Object System.Drawing.Drawing2D.GraphicsPath
  $path.AddArc($X, $Y, $diameter, $diameter, 180, 90)
  $path.AddArc($X + $Width - $diameter, $Y, $diameter, $diameter, 270, 90)
  $path.AddArc(
    $X + $Width - $diameter,
    $Y + $Height - $diameter,
    $diameter,
    $diameter,
    0,
    90
  )
  $path.AddArc($X, $Y + $Height - $diameter, $diameter, $diameter, 90, 90)
  $path.CloseFigure()
  return $path
}

function New-WerklyIcon {
  param(
    [int]$Size,
    [string]$OutputPath
  )
  $bitmap = New-Object System.Drawing.Bitmap($Size, $Size)
  $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
  $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
  $graphics.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAliasGridFit
  $graphics.Clear([System.Drawing.ColorTranslator]::FromHtml('#17231F'))

  $margin = $Size * 0.205
  $markSize = $Size - ($margin * 2)
  $path = New-RoundedPath -X $margin -Y $margin -Width $markSize -Height $markSize -Radius ($Size * 0.15)
  $orangeBrush = New-Object System.Drawing.SolidBrush(
    [System.Drawing.ColorTranslator]::FromHtml('#F2A94A')
  )
  $graphics.FillPath($orangeBrush, $path)

  $font = New-Object System.Drawing.Font(
    $fontFamily,
    ($Size * 0.40),
    [System.Drawing.FontStyle]::Regular,
    [System.Drawing.GraphicsUnit]::Pixel
  )
  $format = New-Object System.Drawing.StringFormat
  $format.Alignment = [System.Drawing.StringAlignment]::Center
  $format.LineAlignment = [System.Drawing.StringAlignment]::Center
  $inkBrush = New-Object System.Drawing.SolidBrush(
    [System.Drawing.ColorTranslator]::FromHtml('#17231F')
  )
  $rect = New-Object System.Drawing.RectangleF(0, ($Size * -0.015), $Size, $Size)
  $graphics.DrawString('W', $font, $inkBrush, $rect, $format)

  $outputDir = Split-Path -Parent $OutputPath
  New-Item -ItemType Directory -Force -Path $outputDir | Out-Null
  $bitmap.Save($OutputPath, [System.Drawing.Imaging.ImageFormat]::Png)

  $inkBrush.Dispose()
  $format.Dispose()
  $font.Dispose()
  $orangeBrush.Dispose()
  $path.Dispose()
  $graphics.Dispose()
  $bitmap.Dispose()
}

$sourceCopy = Join-Path $storeDir 'feature-illustration-source.png'
Copy-Item -LiteralPath $IllustrationPath -Destination $sourceCopy -Force

$featurePath = Join-Path $storeDir 'feature-graphic-1024x500.png'
$feature = New-Object System.Drawing.Bitmap(1024, 500)
$featureGraphics = [System.Drawing.Graphics]::FromImage($feature)
$featureGraphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
$featureGraphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
$featureGraphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
$featureGraphics.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAliasGridFit
$featureGraphics.Clear([System.Drawing.ColorTranslator]::FromHtml('#F7F7F2'))

$illustration = [System.Drawing.Image]::FromFile($sourceCopy)
$sourceHeight = [int]([math]::Round($illustration.Width / (1024 / 500)))
$sourceY = [int](($illustration.Height - $sourceHeight) * 0.55)
$destination = New-Object System.Drawing.Rectangle(0, 0, 1024, 500)
$source = New-Object System.Drawing.Rectangle(0, $sourceY, $illustration.Width, $sourceHeight)
$featureGraphics.DrawImage(
  $illustration,
  $destination,
  $source.X,
  $source.Y,
  $source.Width,
  $source.Height,
  [System.Drawing.GraphicsUnit]::Pixel
)

$veilBrush = New-Object System.Drawing.SolidBrush(
  [System.Drawing.Color]::FromArgb(228, 247, 247, 242)
)
$featureGraphics.FillRectangle($veilBrush, 0, 0, 520, 500)

$logoPath = New-RoundedPath -X 62 -Y 54 -Width 58 -Height 58 -Radius 16
$orangeBrush = New-Object System.Drawing.SolidBrush(
  [System.Drawing.ColorTranslator]::FromHtml('#F2A94A')
)
$featureGraphics.FillPath($orangeBrush, $logoPath)
$inkBrush = New-Object System.Drawing.SolidBrush(
  [System.Drawing.ColorTranslator]::FromHtml('#17231F')
)
$greenBrush = New-Object System.Drawing.SolidBrush(
  [System.Drawing.ColorTranslator]::FromHtml('#2F6B55')
)
$logoFont = New-Object System.Drawing.Font(
  $fontFamily,
  32,
  [System.Drawing.FontStyle]::Regular,
  [System.Drawing.GraphicsUnit]::Pixel
)
$logoFormat = New-Object System.Drawing.StringFormat
$logoFormat.Alignment = [System.Drawing.StringAlignment]::Center
$logoFormat.LineAlignment = [System.Drawing.StringAlignment]::Center
$featureGraphics.DrawString(
  'W',
  $logoFont,
  $inkBrush,
  (New-Object System.Drawing.RectangleF(62, 51, 58, 58)),
  $logoFormat
)

$brandFont = New-Object System.Drawing.Font(
  $fontFamily,
  36,
  [System.Drawing.FontStyle]::Regular,
  [System.Drawing.GraphicsUnit]::Pixel
)
$headlineFont = New-Object System.Drawing.Font(
  $fontFamily,
  34,
  [System.Drawing.FontStyle]::Regular,
  [System.Drawing.GraphicsUnit]::Pixel
)
$bodyFont = New-Object System.Drawing.Font(
  $fontFamily,
  17,
  [System.Drawing.FontStyle]::Regular,
  [System.Drawing.GraphicsUnit]::Pixel
)
$featureGraphics.DrawString('werkly', $brandFont, $inkBrush, 134, 60)
$featureGraphics.DrawString('Dein Werkstudentenjob.', $headlineFont, $inkBrush, 62, 148)
$featureGraphics.DrawString('Besser abgestimmt.', $headlineFont, $inkBrush, 62, 202)
$featureGraphics.DrawString(
  'Jobs  |  KI-Matching  |  Bewerbungsplanung',
  $bodyFont,
  $greenBrush,
  (New-Object System.Drawing.RectangleF(64, 288, 465, 40))
)

$feature.Save($featurePath, [System.Drawing.Imaging.ImageFormat]::Png)

$bodyFont.Dispose()
$headlineFont.Dispose()
$brandFont.Dispose()
$logoFormat.Dispose()
$logoFont.Dispose()
$greenBrush.Dispose()
$inkBrush.Dispose()
$orangeBrush.Dispose()
$logoPath.Dispose()
$veilBrush.Dispose()
$illustration.Dispose()
$featureGraphics.Dispose()
$feature.Dispose()

New-WerklyIcon -Size 512 -OutputPath (Join-Path $storeDir 'app-icon-512.png')

$androidIcons = @{
  'mipmap-mdpi' = 48
  'mipmap-hdpi' = 72
  'mipmap-xhdpi' = 96
  'mipmap-xxhdpi' = 144
  'mipmap-xxxhdpi' = 192
}
foreach ($entry in $androidIcons.GetEnumerator()) {
  $path = Join-Path $projectRoot "android\app\src\main\res\$($entry.Key)\ic_launcher.png"
  New-WerklyIcon -Size $entry.Value -OutputPath $path
}

New-WerklyIcon -Size 192 -OutputPath (Join-Path $projectRoot 'web\icons\Icon-192.png')
New-WerklyIcon -Size 512 -OutputPath (Join-Path $projectRoot 'web\icons\Icon-512.png')
New-WerklyIcon -Size 192 -OutputPath (Join-Path $projectRoot 'web\icons\Icon-maskable-192.png')
New-WerklyIcon -Size 512 -OutputPath (Join-Path $projectRoot 'web\icons\Icon-maskable-512.png')
New-WerklyIcon -Size 32 -OutputPath (Join-Path $projectRoot 'web\favicon.png')

$fonts.Dispose()

Write-Output "Generated: $featurePath"
Write-Output "Generated: $(Join-Path $storeDir 'app-icon-512.png')"
Write-Output 'Updated Android and web launcher icons.'
