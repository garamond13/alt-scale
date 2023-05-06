# Alt scale
Alt scale is a mpv shader. A 2 pass scaler, an alternative to mpv's built in scaling.

`Chroma` folder contains shaders for upscaling chroma only \
`Luma` folder contains shaders for upscaling and downscaling luma only

`altUpscale` is optimised for and only does upscaling\
`altUpscaleUnsharp` is optimised for and only does upscaling, also provides unsharp mask\
`altUpscaleHDR` is optimised for and only does upscaling; HDR version\
`altUpscaleUnsharpHDR` is optimised for and only does upscaling, also provides unsharp mask; HDR version\
`altDownscale` is optimised for and only does downscaling\
`altDownscaleUnsharp` is optimised for and only does downscaling, also provides unsharp mask\
`altDownscaleGaussian` is optimised for and only does downscaling, also provides gaussian blur\
`altDownscaleGaussianUnsharp` is optimised for and only does downscaling, also provides gaussian blur and unsharp mask

## Usage
- If you place this shader in the same folder as your `mpv.conf`, you can use it with `glsl-shaders-append="~~/FILE_NAME"`. For an example `glsl-shaders-append="~~/altUpscale.glsl"`.
- Requires `vo=gpu-next`.
- Note that defualt settings are "simbolic" only, should change them to your liking.
- Note that all downscale shaders can be used for both SDR and HDR content.
- Note that HDR versions are just gamma light so you can use them for SDR

## Settings

For better understanding of these settings see research https://github.com/garamond13/Finding-the-best-methods-for-image-scaling

#### Kernel function (K)
Which kernel function to use for calculation of kernel weights. See "KERNEL functions LIST" inside the shader for available kernel functions.

#### Kernel radius (R)
Kernel radius determines the kernel size, which is `ceil(2 * kernel radius)` when upsampling (upscale) or `ceil(2 * kernel radius * downscale ratio * antialiasing amount)` when downsampling (downscale).

#### Kernel blur (B)
Effectively values smaller than 1 sharpen the kernel and values larger than 1 blur the kernel, 1 is neutral or no effect. Only affects widowed sinc kernels.

#### Antiringing (AR) (Only for upscale)
Reduces ringing artifacts.

#### Antialiasing (AA) (Only for downscale)
Effectively trades between aliasing and ringing artifacts. The default value is 1.0.

#### Kernel functions parameters (P1) and (P2)
Some kernel functions take additional parameters, they are set here. \
See references for: \
COSINE (power of cosine) - https://en.wikipedia.org/wiki/Window_function#Power-of-sine/cosine_windows \
GARAMOND (power of garamond) - https://github.com/garamond13/power-of-garamond-window \
BLACKMAN (power of blackman)- https://github.com/garamond13/power-of-blackman \
GNW (generalized normal window) - https://ieeexplore.ieee.org/document/6638833 \
SAID - https://www.hpl.hp.com/techreports/2007/HPL-2007-179.pdf \
FSR (modified fsr kernel, based on https://github.com/GPUOpen-Effects/FidelityFX-FSR) - for referernce see the research above \
BCSPLINE - https://www.cs.utexas.edu/~fussell/courses/cs384g-fall2013/lectures/mitchell/Mitchell.pdf

#### Sigmoidal curve settings (C) and (M) (Only for upscale and not part of HDR versions)
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
