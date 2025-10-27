# Alt scale

Alt scale is a mpv shader. A 2 pass scaler, an alternative to mpv's built in scaling.

`Chroma` folder contains shaders for upscaling chroma only \
`Luma` folder contains shaders for upscaling and downscaling luma only

`altUpscale` is optimised for and only does upscaling\
`altUpscaleUnsharp` is optimised for and only does upscaling, also provides unsharp mask\
`altDownscale` is optimised for and only does downscaling\
`altDownscaleUnsharp` is optimised for and only does downscaling, also provides unsharp mask\
`altDownscaleGaussian` is optimised for and only does downscaling, also provides gaussian blur\
`altDownscaleGaussianUnsharp` is optimised for and only does downscaling, also provides gaussian blur and unsharp mask

## Usage

- If you place this shader in the same folder as your `mpv.conf`, you can use it with `glsl-shaders-append="~~/FILE_NAME"`. For an example `glsl-shaders-append="~~/altUpscale.glsl"`.
- Requires `vo=gpu-next`.
- Note that defualt settings are "simbolic" only, should change them to your liking.

## Settings

For better understanding of these settings see research https://github.com/garamond13/Finding-the-best-methods-for-image-scaling  
For finding the best parameters you can use [BestScalingParamsFinder](https://github.com/garamond13/BestScalingParamsFinder)

#### Kernel function (K)

Which kernel function to use for calculation of kernel weights. See "KERNEL functions LIST" inside the shader for available kernel functions.

#### Kernel radius (R)

Kernel radius determines the kernel size, which is `ceil(2 * kernel radius)` when upsampling (upscale) or `ceil(2 * kernel radius * downscale ratio * antialiasing amount)` when downsampling (downscale).

#### Kernel blur (B)

Effectively values smaller than 1 sharpen the kernel and values larger than 1 blur the kernel, 1 is neutral or no effect. Only affects widowed sinc kernels.

#### Antiringing (AR) (Only for upscale)

Reduces ringing artifacts.

#### Kernel functions parameters (P1) and (P2)

Some kernel functions take additional parameters, they are set here. \
**COSINE** (Power of Cosine) - https://en.wikipedia.org/wiki/Window_function#Power-of-sine/cosine_windows \
n = P1  
Has to be satisfied: n >= 0  
n = 0: Box window  
n = 1: Cosine window  
n = 2: Hann window  
**GARAMOND** (Power of Garamond) - https://github.com/garamond13/power-of-garamond-window \
n = P1, m = P2  
Has to be satisfied: n >= 0, m >= 0  
n = 0: Box window  
m = 0: Box window  
n -> inf, m <= 1: Box window  
m = 1: Garamond window  
n = 1, m = 1: Linear window  
n = 2, m = 1: Welch window  
**BLACKMAN** (Power of Blackman)- https://github.com/garamond13/power-of-blackman \
a = P1, n = P2  
Has to be satisfied: n >= 0  
Has to be satisfied: if n != 1, a <= 0.16  
n = 0: Box window  
n = 1: Blackman window  
a = 0, n = 1: Hann window  
a = 0, n = 0.5: Cosine window  
**GNW** (Generalized Normal Window) - https://ieeexplore.ieee.org/document/6638833 \
s = P1, n = P2  
Has to be satisfied: s != 0, n >= 0  
n -> inf: Box window  
n = 2: Gaussian window  
**SAID** - https://www.hpl.hp.com/techreports/2007/HPL-2007-179.pdf \
eta = P1, chi = P2  
Has to be satisfied: eta != 2  
**FSR** (Modified FSR kernel, based on https://github.com/GPUOpen-Effects/FidelityFX-FSR) - for referernce see the research above \
b = P1, c = P2  
Has to be satisfied: b != 0, b != 2, c != 0  
c = 1: FSR kernel  
**BCSPLINE** - https://www.cs.utexas.edu/~fussell/courses/cs384g-fall2013/lectures/mitchell/Mitchell.pdf  
B = P1, C = P2  
Keys kernels: B + 2C = 1  
B = 1, C = 0: Spline kernel  
B = 0, C = 0: Hermite kernel  
B = 0, C = 0.5: Catmull-Rom kernel  
B = 1 / 3, C = 1 / 3: Mitchell kernel  
B = 12 / (19 + 9 * sqrt(2)), C = 113 / (58 + 216 * sqrt(2)): Robidoux kernel  
B = 6 / (13 + 7 * sqrt(2)), C = 7 / (2 + 12 * sqrt(2)): RobidouxSharp kernel  
B = (9 - 3 * sqrt(2)) / 7, C = 0.1601886205085204: RobidouxSoft kernel  

#### Sigmoidal curve settings (C) and (M) (Only for upscale versions)

Contrast `C` is equivalent to mpv's `--sigmoid-slope` and midpoint `M` is equivalent to mpv's `--sigmoid-center`.

### Gaussian blur and unsharp mask (Only for gaussian and unsharp versions)

- Unsharp mask works like this: `sharpened = original + (original − blurred) * amount`.
- Blur kernel radius is independent from scaling kernel radius.
- For shaders with both unsharp mask and gaussian blur all settings are independent.

#### Blur spread or amount (S)

Gaussian blur sigma value, controls the blur intensity and how much it will be spread accros the blur kernel.

#### Blur kernel radius (R)

Determines how many neighboring pixels will contribute to the blurred value of the center pixel inside the blur kernel.

#### Sharpening amount (A) (Only for unsharp versions)

Sharpening amount or strenght.
