# =====================================================================
# Welcome to the Binary Globe Project - by Andy Baker
#
# Free to use, modify and distribute. See the included LICENCE file for
# terms.
#
# This script renders a rotating digital Earth using PowerShell, WPF
# and an embedded C# rendering engine.
#
# The globe itself is generated as a true spherical projection rather
# than a flat image. A real-world land mask is wrapped around the sphere
# and the land masses are drawn using green binary code.
#
# A subtle animated starfield sits behind the Earth, with independently
# twinkling stars to give the background a more natural night-sky feel.
#
# The script also detects the computer's primary local IPv4 address and
# then uses the public Internet IP to obtain an approximate geographic
# location. That position is mapped onto the rotating Earth and shown
# as a red X. IP-based location is approximate and may represent an ISP
# or network location rather than the computer's exact physical position.
#
# Keyboard Controls
#
#   L      = Toggle the location X on / off
#   S      = Toggle the starfield on / off
#   X      = Toggle the on-screen control prompts on / off
#   SPACE  = Pause / resume Earth rotation
#   ESC    = Close the globe
#
# The location marker remains fixed to its geographic coordinates, so it
# rotates naturally with the Earth and disappears when it moves onto the
# far side of the globe.
#
# Please read the instructions on how to modify the variables for a
# desired output.
#
# Any questions or queries please email Killerbite@gmail.com
#
# =====================================================================

Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName PresentationCore
Add-Type -AssemblyName WindowsBase


$RendererTypeName = 'CodeSphereRendererBasic'

if (-not ($RendererTypeName -as [type])) {

    $source = @'
using System;
using System.IO;
using System.IO.Compression;

public class CodeSphereRendererBasic
{
    private readonly int width;
    private readonly int height;

    private readonly int textureWidth  = 2048;
    private readonly int textureHeight = 1024;

    private const int LandMaskWidth  = 1024;
    private const int LandMaskHeight = 512;

    private readonly byte[] texture;

    private readonly byte[] landMask;

    private readonly byte[] pixels;

    private readonly Random random = new Random(123456);

    private static readonly int[] Glyph0 =
    {
        0b01110,
        0b10001,
        0b10011,
        0b10101,
        0b11001,
        0b10001,
        0b01110
    };

    private static readonly int[] Glyph1 =
    {
        0b00100,
        0b01100,
        0b00100,
        0b00100,
        0b00100,
        0b00100,
        0b01110
    };

    private const string LandMaskBase64 = @"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";

    public byte[] Pixels
    {
        get { return pixels; }
    }

    public int Stride
    {
        get { return width * 4; }
    }

    public CodeSphereRendererBasic(int width, int height)
    {
        if (width <= 0 || height <= 0)
            throw new ArgumentOutOfRangeException("Render dimensions must be positive.");

        this.width  = width;
        this.height = height;

        texture = new byte[textureWidth * textureHeight];
        pixels  = new byte[width * height * 4];

        landMask = DecodeLandMask();

        BuildBinaryTexture();
    }


    private byte[] DecodeLandMask()
    {
        byte[] compressed =
            Convert.FromBase64String(LandMaskBase64);

        using (MemoryStream input = new MemoryStream(compressed))
        using (GZipStream gzip = new GZipStream(input, CompressionMode.Decompress))
        using (MemoryStream output = new MemoryStream())
        {
            gzip.CopyTo(output);

            byte[] result = output.ToArray();

            int expected =
                (LandMaskWidth * LandMaskHeight + 7) / 8;

            if (result.Length != expected)
            {
                throw new InvalidOperationException(
                    "Embedded Earth land mask is invalid.");
            }

            return result;
        }
    }

    private bool IsLandMaskPixel(int x, int y)
    {
        if (
            x < 0 ||
            x >= LandMaskWidth ||
            y < 0 ||
            y >= LandMaskHeight)
        {
            return false;
        }

        int index =
            (y * LandMaskWidth) + x;

        int byteIndex =
            index >> 3;

        int bit =
            7 - (index & 7);

        return
            ((landMask[byteIndex] >> bit) & 1) != 0;
    }

    private bool IsLandTexturePixel(int tx, int ty)
    {
        int mx =
            (tx * LandMaskWidth) /
            textureWidth;

        int my =
            (ty * LandMaskHeight) /
            textureHeight;

        if (mx >= LandMaskWidth)
            mx = LandMaskWidth - 1;

        if (my >= LandMaskHeight)
            my = LandMaskHeight - 1;

        return IsLandMaskPixel(mx, my);
    }


    private void BuildBinaryTexture()
    {
        int cellW = 8;
        int cellH = 11;

        for (int cy = 0; cy < textureHeight; cy += cellH)
        {
            for (int cx = 0; cx < textureWidth; cx += cellW)
            {
                int centreX =
                    Math.Min(textureWidth - 1, cx + 3);

                int centreY =
                    Math.Min(textureHeight - 1, cy + 5);

                if (!IsLandTexturePixel(centreX, centreY))
                    continue;

                if (random.NextDouble() < 0.025)
                    continue;

                bool one =
                    random.Next(0, 2) == 1;

                double longitude =
                    (((double)centreX / textureWidth) - 0.5) *
                    Math.PI * 2.0;

                double latitude =
                    (0.5 - ((double)centreY / textureHeight)) *
                    Math.PI;

                double pattern =
                    0.74 +
                    Math.Sin(
                        longitude * 3.0 +
                        latitude * 2.0
                    ) * 0.10 +
                    Math.Cos(
                        longitude * 7.0 -
                        latitude * 5.0
                    ) * 0.06 +
                    Math.Sin(
                        longitude * 13.0 +
                        latitude * 9.0
                    ) * 0.04;

                pattern +=
                    (random.NextDouble() - 0.5) * 0.07;

                if (pattern < 0.38)
                    pattern = 0.38;

                if (pattern > 1.0)
                    pattern = 1.0;

                byte intensity =
                    (byte)Math.Max(
                        1,
                        Math.Min(
                            255,
                            (int)(255.0 * pattern)));

                DrawGlyph(
                    cx + 1,
                    cy + 2,
                    one,
                    intensity);
            }
        }
    }

    private void DrawGlyph(
        int x,
        int y,
        bool one,
        byte intensity)
    {
        int[] glyph =
            one ? Glyph1 : Glyph0;

        for (int gy = 0; gy < 7; gy++)
        {
            int row =
                glyph[gy];

            for (int gx = 0; gx < 5; gx++)
            {
                int bit =
                    1 << (4 - gx);

                if ((row & bit) == 0)
                    continue;

                int tx =
                    x + gx;

                int ty =
                    y + gy;

                if (
                    tx < 0 ||
                    tx >= textureWidth ||
                    ty < 0 ||
                    ty >= textureHeight)
                {
                    continue;
                }

                if (!IsLandTexturePixel(tx, ty))
                    continue;

                texture[(ty * textureWidth) + tx] =
                    intensity;
            }
        }
    }


    public void Render(double angle)
    {
        Array.Clear(
            pixels,
            0,
            pixels.Length);

        double centreX =
            width / 2.0;

        double centreY =
            height / 2.0;

        double radius =
            Math.Min(width, height) * 0.455;

        double cosA =
            Math.Cos(angle);

        double sinA =
            Math.Sin(angle);

        double twoPi =
            Math.PI * 2.0;

        int minX =
            Math.Max(
                0,
                (int)(centreX - radius - 2));

        int maxX =
            Math.Min(
                width - 1,
                (int)(centreX + radius + 2));

        int minY =
            Math.Max(
                0,
                (int)(centreY - radius - 2));

        int maxY =
            Math.Min(
                height - 1,
                (int)(centreY + radius + 2));

        for (int py = minY; py <= maxY; py++)
        {
            double ny =
                -(py - centreY) / radius;

            for (int px = minX; px <= maxX; px++)
            {
                double nx =
                    (px - centreX) / radius;

                double r2 =
                    (nx * nx) +
                    (ny * ny);

                if (r2 > 1.0)
                    continue;

                double nz =
                    Math.Sqrt(1.0 - r2);

                double ox =
                    (nx * cosA) -
                    (nz * sinA);

                double oy =
                    ny;

                double oz =
                    (nx * sinA) +
                    (nz * cosA);

                double longitude =
                    Math.Atan2(
                        oz,
                        ox);

                double latitude =
                    Math.Asin(
                        Math.Max(
                            -1.0,
                            Math.Min(
                                1.0,
                                oy)));

                double u =
                    0.5 - (longitude / twoPi);

                double v =
                    0.5 -
                    (latitude / Math.PI);

                u =
                    u - Math.Floor(u);

                int tx =
                    (int)(u * textureWidth);

                int ty =
                    (int)(v * textureHeight);

                if (tx < 0)
                    tx = 0;

                if (tx >= textureWidth)
                    tx = textureWidth - 1;

                if (ty < 0)
                    ty = 0;

                if (ty >= textureHeight)
                    ty = textureHeight - 1;

                byte tex =
                    texture[
                        (ty * textureWidth) + tx
                    ];

                if (tex == 0)
                    continue;


                double depthLight =
                    Math.Pow(
                        nz,
                        0.52);

                double directional =
                    (nx * -0.16) +
                    (ny *  0.12) +
                    (nz *  0.98);

                if (directional < 0.0)
                    directional = 0.0;

                double lighting =
                    0.14 +
                    (depthLight * 0.62) +
                    (directional * 0.24);

                if (lighting > 1.0)
                    lighting = 1.0;

                double rim =
                    Math.Pow(
                        nz,
                        0.48);

                lighting *=
                    0.30 +
                    (rim * 0.70);

                int outputGreen =
                    (int)(tex * lighting);

                if (outputGreen < 1)
                    outputGreen = 1;

                if (outputGreen > 255)
                    outputGreen = 255;

                int outputBlue =
                    (int)(outputGreen * 0.05);

                if (outputBlue > 16)
                    outputBlue = 16;

                int outputIndex =
                    ((py * width) + px) * 4;

                pixels[outputIndex + 0] =
                    (byte)outputBlue;

                pixels[outputIndex + 1] =
                    (byte)outputGreen;

                pixels[outputIndex + 2] =
                    0;

                pixels[outputIndex + 3] =
                    255;
            }
        }
    }
}
'@

    try {
        Add-Type `
            -TypeDefinition $source `
            -Language CSharp `
            -ErrorAction Stop
    }
    catch {
        [System.Windows.MessageBox]::Show(
            "The renderer could not be compiled.`r`n`r`n$($_.Exception.Message)",
            "Code Globe - Basic",
            [System.Windows.MessageBoxButton]::OK,
            [System.Windows.MessageBoxImage]::Error
        ) | Out-Null

        return
    }
}


$RenderWidth  = 600
$RenderHeight = 600

try {

    $Renderer =
        [CodeSphereRendererBasic]::new(
            $RenderWidth,
            $RenderHeight
        )

    if ($null -eq $Renderer) {
        throw "CodeSphereRendererBasic returned a null object."
    }

    $Bitmap =
        [System.Windows.Media.Imaging.WriteableBitmap]::new(
            $RenderWidth,
            $RenderHeight,
            96,
            96,
            [System.Windows.Media.PixelFormats]::Bgra32,
            $null
        )

    $Rect =
        [System.Windows.Int32Rect]::new(
            0,
            0,
            $RenderWidth,
            $RenderHeight
        )
}
catch {

    [System.Windows.MessageBox]::Show(
        "The globe renderer could not be created.`r`n`r`n$($_.Exception.Message)",
        "Code Globe - Basic",
        [System.Windows.MessageBoxButton]::OK,
        [System.Windows.MessageBoxImage]::Error
    ) | Out-Null

    return
}


$Window =
    New-Object System.Windows.Window

$Window.Title =
    "Code Globe - Basic"

$Window.Width =
    1000

$Window.Height =
    800

$Window.WindowStartupLocation =
    "CenterScreen"

$Window.Background =
    [System.Windows.Media.Brushes]::Black

$Window.UseLayoutRounding =
    $true

$Grid =
    New-Object System.Windows.Controls.Grid

$Grid.Background =
    [System.Windows.Media.Brushes]::Black

$Window.Content =
    $Grid

$Image =
    New-Object System.Windows.Controls.Image

$Image.Source =
    $Bitmap

$Image.Width =
    $RenderWidth

$Image.Height =
    $RenderHeight

$Image.HorizontalAlignment =
    "Center"

$Image.VerticalAlignment =
    "Center"

$Image.Stretch =
    [System.Windows.Media.Stretch]::None

[System.Windows.Media.RenderOptions]::SetBitmapScalingMode(
    $Image,
    [System.Windows.Media.BitmapScalingMode]::HighQuality
)

$Grid.Children.Add(
    $Image
) | Out-Null


$script:Angle =
    1.22

$script:RenderFaulted =
    $false

$RadiansPerSecond =
    0.08

$Clock =
    [System.Diagnostics.Stopwatch]::StartNew()

$script:LastTime =
    $Clock.Elapsed.TotalSeconds

$Timer =
    New-Object System.Windows.Threading.DispatcherTimer

$Timer.Interval =
    [TimeSpan]::FromMilliseconds(33)

$Timer.Add_Tick({

    if (
        $script:RenderFaulted -or
        $null -eq $Renderer -or
        $null -eq $Bitmap
    ) {
        $Timer.Stop()
        return
    }

    $Now =
        $Clock.Elapsed.TotalSeconds

    $Delta =
        $Now - $script:LastTime

    $script:LastTime =
        $Now
if ($Delta -gt 0.1) {
        $Delta = 0.1
    }

    $script:Angle +=
        $RadiansPerSecond * $Delta

    if ($script:Angle -gt ([Math]::PI * 2)) {
        $script:Angle -= ([Math]::PI * 2)
    }

    try {

        $Renderer.Render(
            $script:Angle
        )

        $Bitmap.WritePixels(
            $Rect,
            $Renderer.Pixels,
            $Renderer.Stride,
            0
        )
    }
    catch {

        $script:RenderFaulted =
            $true

        $Timer.Stop()

        [System.Windows.MessageBox]::Show(
            "The globe renderer stopped because of an error.`r`n`r`n$($_.Exception.Message)",
            "Code Globe - Basic",
            [System.Windows.MessageBoxButton]::OK,
            [System.Windows.MessageBoxImage]::Error
        ) | Out-Null
    }
})


$Window.Add_ContentRendered({

    try {

        $Renderer.Render(
            $script:Angle
        )

        $Bitmap.WritePixels(
            $Rect,
            $Renderer.Pixels,
            $Renderer.Stride,
            0
        )

        $script:LastTime =
            $Clock.Elapsed.TotalSeconds

        $Timer.Start()
    }
    catch {

        $script:RenderFaulted =
            $true

        $Timer.Stop()

        [System.Windows.MessageBox]::Show(
            "The initial globe frame could not be rendered.`r`n`r`n$($_.Exception.Message)",
            "Code Globe - Basic",
            [System.Windows.MessageBoxButton]::OK,
            [System.Windows.MessageBoxImage]::Error
        ) | Out-Null
    }
})

$Window.Add_Closed({

    $Timer.Stop()
    $Clock.Stop()
})

$Window.ShowDialog() | Out-Null