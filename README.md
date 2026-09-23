# PowerShell Code Globe - By Andy Baker



Question and/or queries - killerbite@gmail.com



A rotating digital Earth rendered with PowerShell, WPF and an embedded C# rendering engine.



The project uses a real-world land mask wrapped around a mathematically rendered sphere. Land is drawn from small binary 0 and 1 characters while the oceans remain blank black space, giving the globe a code / terminal-style appearance without using an external image or 3D engine.



Free to use, modify and distribute under the MIT License. See LICENSE.



## Included versions:



### Globe-Basic.ps1

The basic version contains only the rotating digital Earth.

It has:

* the spherical Earth renderer
* the real-world land mask
* binary land rendering
* blank black oceans
* continuous Earth rotation
* no starfield
* no IP lookup
* no location marker
* no prompts
* no keyboard toggles



Close it using the normal window close button (Esc).



### Globe-Advanced.ps1

The advanced version builds on the same Earth renderer and adds:

* a faded starfield around the Earth
* independently twinkling stars
* automatic local IPv4 detection
* approximate public-IP geolocation
* a red X fixed to the detected geographic position
* on-screen keyboard prompts
* runtime toggles
* automatic exclusion of stars from the Earth disc



The private LAN address is read for information, but a private address such as 192.168.x.x or 10.x.x.x cannot provide a geographic location. The script therefore uses the public Internet IP for approximate latitude and longitude. IP geolocation can resolve to an ISP or network point rather than an exact physical address.



The advanced version currently tries ipwho.is first and ipapi.co as a fallback. If geolocation is unavailable, the globe still runs without the red location marker.



## Advanced keyboard controls



|Key|Action|
|-|-|
|L|Toggle the red location X on/off|
|S|Toggle the starfield on/off|
|X|Toggle the on-screen prompt on/off|
|Space|Pause/resume Earth rotation|
|Esc|Close the globe|

## 

## Running the scripts

From PowerShell:

powershell
.\\Globe-Basic.ps1


or:

powershell
.\\Globe-Advanced.ps1


If the local execution policy blocks unsigned scripts, you can launch a script for that process with:

powershell
powershell.exe -ExecutionPolicy Bypass -File .\\Globe-Advanced.ps1


No third-party PowerShell modules are required.



# Customisation



The values below can be edited directly in the scripts.



## Earth rotation speed

Search for:


$RadiansPerSecond =
    0.08


The default 0.08 is approximately one complete rotation every 79 seconds.

Approximate rotation time:


seconds per revolution = 6.28318 / RadiansPerSecond


Examples:

|Value|Approximate revolution|
|-:|-:|
|0.04|157 seconds|
|0.06|105 seconds|
|0.08|79 seconds|
|0.10|63 seconds|
|0.15|42 seconds|



Increase the value for faster rotation. Decrease it for slower rotation.



## Animation frame rate

Search for:


$Timer.Interval =
    \[TimeSpan]::FromMilliseconds(33)


33 ms is roughly 30 FPS.



Typical values:

text
16 ms  = about 60 FPS
25 ms  = about 40 FPS
33 ms  = about 30 FPS
50 ms  = about 20 FPS


Lower values produce smoother motion but use more CPU.



## Render resolution



Search for:


$RenderWidth  = 600
$RenderHeight = 600


Increasing these values can make the globe sharper, but the renderer has more pixels to calculate every frame.

For example:


$RenderWidth  = 800
$RenderHeight = 800


If you change the render dimensions, keep both values the same unless you deliberately want a non-square render target.



## Window size

Search for:


$Window.Width =
    1000

$Window.Height =
    800


These control the application window rather than the rendered Earth resolution.



## Globe size inside the render area

Inside the embedded C# renderer, search for:

csharp
double radius =
    Math.Min(width, height) \* 0.455;


0.455 means the radius uses 45.5% of the render area.

Examples:


0.40  smaller globe
0.455 current globe
0.48  larger globe


Keep the value below 0.50 or the globe will begin to touch/crop against the edge of its render area.



In the advanced version, the starfield exclusion calculation uses the same 0.455 value. If you change the globe radius, change the matching star exclusion value as well.



## Binary character density

Inside the C# method that builds the Earth texture, search for:

csharp
int cellW = 8;
int cellH = 11;


These control the spacing of the binary glyphs on the land texture.

Smaller values create denser code:

csharp
int cellW = 6;
int cellH = 9;


Larger values create more open spacing:

csharp
int cellW = 10;
int cellH = 14;


Very small values will increase the amount of detail in the generated texture.



## Earth colour

The renderer writes pixels in BGRA order.

Search inside the C# rendering section for:

csharp
pixels\[outputIndex + 0] =
    (byte)outputBlue;

pixels\[outputIndex + 1] =
    (byte)outputGreen;

pixels\[outputIndex + 2] =
    0;


The channels are:

text
+0 = Blue
+1 = Green
+2 = Red
+3 = Alpha


The current Earth is primarily green.



### Cyan Earth

Change the output to:

csharp
pixels\[outputIndex + 0] =
    (byte)outputGreen;

pixels\[outputIndex + 1] =
    (byte)outputGreen;

pixels\[outputIndex + 2] =
    0;


### Red Earth

Use:

csharp
pixels\[outputIndex + 0] =
    0;

pixels\[outputIndex + 1] =
    0;

pixels\[outputIndex + 2] =
    (byte)outputGreen;


### White / grey Earth

Use:

csharp
pixels\[outputIndex + 0] =
    (byte)outputGreen;

pixels\[outputIndex + 1] =
    (byte)outputGreen;

pixels\[outputIndex + 2] =
    (byte)outputGreen;


### Purple Earth

For example:

csharp
pixels\[outputIndex + 0] =
    (byte)outputGreen;

pixels\[outputIndex + 1] =
    0;

pixels\[outputIndex + 2] =
    (byte)outputGreen;


You can also multiply a channel to create more subtle colours.

Example:

csharp
pixels\[outputIndex + 2] =
    (byte)(outputGreen \* 0.35);


## Earth brightness

The main land brightness ultimately comes from:

csharp
int outputGreen =
    (int)(tex \* lighting);


The lighting calculation controls the spherical shading and edge falloff. The generated tex value controls the brightness variation of the binary texture.



If you only want a global brightness adjustment, a simple option is:

csharp
int outputGreen =
    (int)(tex \* lighting \* 0.75);


Use a value below 1.0 to dim the globe.



## Starting longitude

The basic version uses a fixed initial angle:


$script:Angle =
    1.22


Changing this rotates the Earth to a different initial longitude.



The advanced version calculates its initial angle from the detected public-IP longitude so the location marker is visible when the application starts.



# Advanced starfield settings

The following settings only exist in Globe-Advanced.ps1.



## Star density

Search for:


$targetStars =
    \[Math]::Max(
        140,
        \[int](($Width \* $Height) / 2500)
    )


The important value is 2500.

Lower denominator = more stars.

Higher denominator = fewer stars.

Examples:


/ 4000  fewer stars
/ 2500  current density
/ 1800  more stars
/ 1200  dense starfield


The 140 is the minimum number of stars generated.



## Star sizes

Search for:


if ($sizeRoll -lt 0.78) {
    $size = 2.2
}
elseif ($sizeRoll -lt 0.96) {
    $size = 3.2
}
else {
    $size = 4.4
}


The three size values are the star diameters.

The thresholds also control how common each size is:

text
78% approximately 2.2 px
18% approximately 3.2 px
4%  approximately 4.4 px


Changing the sizes changes how prominent the stars appear without changing their count.



## Star opacity

Search for:


$opacity =
    0.20 + ($rng.NextDouble() \* 0.50)


This produces random opacity between 0.20 and 0.70.

Examples:


0.10 + ($rng.NextDouble() \* 0.25)


gives roughly 10%-35%.


0.30 + ($rng.NextDouble() \* 0.60)


gives roughly 30%-90%.

Keep some variation so the sky does not look artificially uniform.



## Star colour

Search for:


$tone =
    145 + \[int]($rng.NextDouble() \* 60)

$blue =
    135 + \[int]($rng.NextDouble() \* 40)


and:


\[System.Windows.Media.Color]::FromRgb(
    \[byte]$tone,
    \[byte]$tone,
    \[byte]$blue
)


These values currently give the stars a slightly varied, subdued night-sky tone.

For pure white stars:


\[System.Windows.Media.Color]::FromRgb(
    \[byte]255,
    \[byte]255,
    \[byte]255
)


Opacity can still be used to keep them subtle.

For pale cyan stars:


\[System.Windows.Media.Color]::FromRgb(
    \[byte]180,
    \[byte]230,
    \[byte]255
)


## Twinkle frequency

Search for:


$cycleSeconds =
    18.0 + ($rng.NextDouble() \* 28.0)


Each star gets a random complete twinkle cycle between approximately 18 and 46 seconds.

For slower twinkling:


$cycleSeconds =
    30.0 + ($rng.NextDouble() \* 45.0)


This gives cycles of approximately 30-75 seconds.

For faster twinkling:


$cycleSeconds =
    8.0 + ($rng.NextDouble() \* 16.0)


This gives cycles of approximately 8-24 seconds.



Random cycle lengths are intentional: if every star has the same timing the whole field begins to pulse together.

## Twinkle start randomisation

Search for:


$twinkle.BeginTime =
    \[TimeSpan]::FromSeconds(
        $rng.NextDouble() \* 25.0
    )


This gives stars different starting points in their animations.



A larger value spreads their initial phases over a wider interval.



## Twinkle intensity

The key values are $minFactor, $midFactor, $nearMax1 and $nearMax2.

Lower minimum factors produce deeper brightness dips.

For more obvious twinkling, reduce the minimum factor values.

For gentler twinkling, raise them closer to 1.0.

For example:


$minFactor = 0.80


barely dims the star.


$minFactor = 0.35


creates a much stronger twinkle.



The advanced script currently uses randomised factors so stars do not all vary by the same amount.



## Star exclusion around Earth

Search for:


$exclusionRadius =
    ($Image.Width \* 0.455) + 10


This prevents stars from appearing inside or over the Earth.

The 10 is an extra safety margin in pixels.

If you enlarge the Earth by changing its 0.455 radius multiplier, update this value to match.

\---

# Advanced location marker



The location X is drawn by the embedded C# renderer so it remains attached to its latitude and longitude as the Earth rotates.

## Marker size

Search for:

csharp
int arm =
    5 + (int)Math.Round(cameraZ \* 3.0);


Increase 5 or 3.0 for a larger X.

Decrease them for a smaller X.



## Marker colour

The marker uses three red shades.

The darker outer stroke uses values similar to:

csharp
125, 0, 0


The main X uses:

csharp
255, 35, 35


The centre uses:

csharp
255, 90, 90


These are RGB values passed to the marker drawing function.

You can replace them with any RGB colour.

For example, cyan:

text
0, 255, 255


Yellow:

text
255, 255, 0


White:

text
255, 255, 255


\---

# On-screen prompt

In the advanced version, search for:


$PromptText.FontSize =
    12


to change its size.

The prompt colour currently uses:

powershell
\[byte]150,
\[byte]205,
\[byte]205


and its opacity is:

powershell
$PromptText.Opacity =
    0.78


The prompt can also be hidden at runtime with X.

\---



# Notes

The embedded Earth mask is stored as compressed Base64 data inside the script. Avoid editing, reformatting or running automated comment-stripping against that Base64 block unless the tool explicitly preserves it. Lines in Base64 data can legitimately begin with characters that look like comment syntax.

Both versions are designed for Windows PowerShell / PowerShell on Windows because the interface uses WPF.

The advanced version requires Internet access only for public-IP geolocation. The globe itself, land mask, binary texture and starfield are self-contained.

