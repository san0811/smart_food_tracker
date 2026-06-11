param()

$ErrorActionPreference = 'Stop'

Add-Type -AssemblyName System.Drawing

$sourcePath = Join-Path (Split-Path -Parent $PSScriptRoot) 'assets\images\Fridgi_logo.jpeg'

Add-Type @"
using System;
using System.Runtime.InteropServices;

public static class NativeMethods {
  [DllImport("user32.dll", CharSet = CharSet.Auto)]
  public static extern bool DestroyIcon(IntPtr hIcon);
}
"@

function New-Canvas {
  param(
    [int]$Size,
    [System.Drawing.Color]$Background
  )

  $canvas = New-Object System.Drawing.Bitmap $Size, $Size, ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
  $canvas.SetResolution(96, 96)

  $graphics = [System.Drawing.Graphics]::FromImage($canvas)
  $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
  $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
  $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
  $graphics.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
  $graphics.Clear($Background)

  return [pscustomobject]@{
    Bitmap = $canvas
    Graphics = $graphics
  }
}

function Write-Png {
  param(
    [System.Drawing.Bitmap]$Bitmap,
    [string]$Path
  )

  $directory = Split-Path -Parent $Path
  if (-not (Test-Path $directory)) {
    New-Item -ItemType Directory -Path $directory | Out-Null
  }

  $Bitmap.Save($Path, [System.Drawing.Imaging.ImageFormat]::Png)
}

function Write-IconImage {
  param(
    [System.Drawing.Bitmap]$Logo,
    [string]$Path,
    [int]$Size,
    [System.Drawing.Color]$Background,
    [double]$Scale
  )

  $canvasWrapper = New-Canvas -Size $Size -Background $Background
  $canvas = $canvasWrapper.Bitmap
  $graphics = $canvasWrapper.Graphics

  try {
    $target = [Math]::Max(1, [int][Math]::Round($Size * $Scale))
    $offset = [int][Math]::Floor(($Size - $target) / 2)
    $rect = New-Object System.Drawing.Rectangle $offset, $offset, $target, $target
    $graphics.DrawImage($Logo, $rect)
    Write-Png -Bitmap $canvas -Path $Path
  }
  finally {
    $graphics.Dispose()
    $canvas.Dispose()
  }
}

function Write-Ico {
  param(
    [System.Drawing.Bitmap]$Logo,
    [string]$Path,
    [int]$Size,
    [double]$Scale
  )

  $canvasWrapper = New-Canvas -Size $Size -Background ([System.Drawing.Color]::White)
  $canvas = $canvasWrapper.Bitmap
  $graphics = $canvasWrapper.Graphics

  try {
    $target = [Math]::Max(1, [int][Math]::Round($Size * $Scale))
    $offset = [int][Math]::Floor(($Size - $target) / 2)
    $rect = New-Object System.Drawing.Rectangle $offset, $offset, $target, $target
    $graphics.DrawImage($Logo, $rect)

    $directory = Split-Path -Parent $Path
    if (-not (Test-Path $directory)) {
      New-Item -ItemType Directory -Path $directory | Out-Null
    }

    $iconHandle = [IntPtr]::Zero
    try {
      $iconHandle = $canvas.GetHicon()
      $icon = [System.Drawing.Icon]::FromHandle($iconHandle)
      try {
        $stream = [System.IO.File]::Open($Path, [System.IO.FileMode]::Create, [System.IO.FileAccess]::Write)
        try {
          $icon.Save($stream)
        }
        finally {
          $stream.Dispose()
        }
      }
      finally {
        $icon.Dispose()
      }
    }
    finally {
      if ($iconHandle -ne [IntPtr]::Zero) {
        [NativeMethods]::DestroyIcon($iconHandle) | Out-Null
      }
    }
  }
  finally {
    $graphics.Dispose()
    $canvas.Dispose()
  }
}

$source = [System.Drawing.Bitmap]::FromFile($sourcePath)
try {
  $logo = $source.Clone(
    (New-Object System.Drawing.Rectangle(0, 0, $source.Width, $source.Height)),
    [System.Drawing.Imaging.PixelFormat]::Format32bppArgb
  )
  try {
    $androidLegacy = @(
      @{ Path = 'android\app\src\main\res\mipmap-mdpi\ic_launcher.png'; Size = 48; Scale = 0.72 },
      @{ Path = 'android\app\src\main\res\mipmap-hdpi\ic_launcher.png'; Size = 72; Scale = 0.72 },
      @{ Path = 'android\app\src\main\res\mipmap-xhdpi\ic_launcher.png'; Size = 96; Scale = 0.72 },
      @{ Path = 'android\app\src\main\res\mipmap-xxhdpi\ic_launcher.png'; Size = 144; Scale = 0.72 },
      @{ Path = 'android\app\src\main\res\mipmap-xxxhdpi\ic_launcher.png'; Size = 192; Scale = 0.72 }
    )

    $androidForeground = @(
      @{ Path = 'android\app\src\main\res\drawable-mdpi\ic_launcher_foreground.png'; Size = 108; Scale = 0.72 },
      @{ Path = 'android\app\src\main\res\drawable-hdpi\ic_launcher_foreground.png'; Size = 162; Scale = 0.72 },
      @{ Path = 'android\app\src\main\res\drawable-xhdpi\ic_launcher_foreground.png'; Size = 216; Scale = 0.72 },
      @{ Path = 'android\app\src\main\res\drawable-xxhdpi\ic_launcher_foreground.png'; Size = 324; Scale = 0.72 },
      @{ Path = 'android\app\src\main\res\drawable-xxxhdpi\ic_launcher_foreground.png'; Size = 432; Scale = 0.72 }
    )

    $iosIcons = @(
      @{ Path = 'ios\Runner\Assets.xcassets\AppIcon.appiconset\Icon-App-20x20@1x.png'; Size = 20 },
      @{ Path = 'ios\Runner\Assets.xcassets\AppIcon.appiconset\Icon-App-20x20@2x.png'; Size = 40 },
      @{ Path = 'ios\Runner\Assets.xcassets\AppIcon.appiconset\Icon-App-20x20@3x.png'; Size = 60 },
      @{ Path = 'ios\Runner\Assets.xcassets\AppIcon.appiconset\Icon-App-29x29@1x.png'; Size = 29 },
      @{ Path = 'ios\Runner\Assets.xcassets\AppIcon.appiconset\Icon-App-29x29@2x.png'; Size = 58 },
      @{ Path = 'ios\Runner\Assets.xcassets\AppIcon.appiconset\Icon-App-29x29@3x.png'; Size = 87 },
      @{ Path = 'ios\Runner\Assets.xcassets\AppIcon.appiconset\Icon-App-40x40@1x.png'; Size = 40 },
      @{ Path = 'ios\Runner\Assets.xcassets\AppIcon.appiconset\Icon-App-40x40@2x.png'; Size = 80 },
      @{ Path = 'ios\Runner\Assets.xcassets\AppIcon.appiconset\Icon-App-40x40@3x.png'; Size = 120 },
      @{ Path = 'ios\Runner\Assets.xcassets\AppIcon.appiconset\Icon-App-50x50@1x.png'; Size = 50 },
      @{ Path = 'ios\Runner\Assets.xcassets\AppIcon.appiconset\Icon-App-50x50@2x.png'; Size = 100 },
      @{ Path = 'ios\Runner\Assets.xcassets\AppIcon.appiconset\Icon-App-57x57@1x.png'; Size = 57 },
      @{ Path = 'ios\Runner\Assets.xcassets\AppIcon.appiconset\Icon-App-57x57@2x.png'; Size = 114 },
      @{ Path = 'ios\Runner\Assets.xcassets\AppIcon.appiconset\Icon-App-60x60@2x.png'; Size = 120 },
      @{ Path = 'ios\Runner\Assets.xcassets\AppIcon.appiconset\Icon-App-60x60@3x.png'; Size = 180 },
      @{ Path = 'ios\Runner\Assets.xcassets\AppIcon.appiconset\Icon-App-72x72@1x.png'; Size = 72 },
      @{ Path = 'ios\Runner\Assets.xcassets\AppIcon.appiconset\Icon-App-72x72@2x.png'; Size = 144 },
      @{ Path = 'ios\Runner\Assets.xcassets\AppIcon.appiconset\Icon-App-76x76@1x.png'; Size = 76 },
      @{ Path = 'ios\Runner\Assets.xcassets\AppIcon.appiconset\Icon-App-76x76@2x.png'; Size = 152 },
      @{ Path = 'ios\Runner\Assets.xcassets\AppIcon.appiconset\Icon-App-83.5x83.5@2x.png'; Size = 167 },
      @{ Path = 'ios\Runner\Assets.xcassets\AppIcon.appiconset\Icon-App-1024x1024@1x.png'; Size = 1024 }
    )

    $macIcons = @(
      @{ Path = 'macos\Runner\Assets.xcassets\AppIcon.appiconset\app_icon_16.png'; Size = 16 },
      @{ Path = 'macos\Runner\Assets.xcassets\AppIcon.appiconset\app_icon_32.png'; Size = 32 },
      @{ Path = 'macos\Runner\Assets.xcassets\AppIcon.appiconset\app_icon_64.png'; Size = 64 },
      @{ Path = 'macos\Runner\Assets.xcassets\AppIcon.appiconset\app_icon_128.png'; Size = 128 },
      @{ Path = 'macos\Runner\Assets.xcassets\AppIcon.appiconset\app_icon_256.png'; Size = 256 },
      @{ Path = 'macos\Runner\Assets.xcassets\AppIcon.appiconset\app_icon_512.png'; Size = 512 },
      @{ Path = 'macos\Runner\Assets.xcassets\AppIcon.appiconset\app_icon_1024.png'; Size = 1024 }
    )

    $webIcons = @(
      @{ Path = 'web\favicon.png'; Size = 48; Scale = 0.72; Background = [System.Drawing.Color]::White },
      @{ Path = 'web\icons\Icon-192.png'; Size = 192; Scale = 0.72; Background = [System.Drawing.Color]::White },
      @{ Path = 'web\icons\Icon-512.png'; Size = 512; Scale = 0.72; Background = [System.Drawing.Color]::White },
      @{ Path = 'web\icons\Icon-maskable-192.png'; Size = 192; Scale = 0.72; Background = [System.Drawing.Color]::Transparent },
      @{ Path = 'web\icons\Icon-maskable-512.png'; Size = 512; Scale = 0.72; Background = [System.Drawing.Color]::Transparent }
    )

    foreach ($item in $androidLegacy) {
      Write-IconImage -Logo $logo -Path $item.Path -Size $item.Size -Background ([System.Drawing.Color]::White) -Scale $item.Scale
    }

    foreach ($item in $androidForeground) {
      Write-IconImage -Logo $logo -Path $item.Path -Size $item.Size -Background ([System.Drawing.Color]::Transparent) -Scale $item.Scale
    }

    foreach ($item in $iosIcons) {
      Write-IconImage -Logo $logo -Path $item.Path -Size $item.Size -Background ([System.Drawing.Color]::White) -Scale 0.86
    }

    foreach ($item in $macIcons) {
      Write-IconImage -Logo $logo -Path $item.Path -Size $item.Size -Background ([System.Drawing.Color]::White) -Scale 0.86
    }

    foreach ($item in $webIcons) {
      Write-IconImage -Logo $logo -Path $item.Path -Size $item.Size -Background $item.Background -Scale $item.Scale
    }

    Write-Ico -Logo $logo -Path 'windows\runner\resources\app_icon.ico' -Size 256 -Scale 0.72
  }
  finally {
    $logo.Dispose()
  }
}
finally {
  $source.Dispose()
}
