# Alt scale
Alt scale is a mpv shader. A 2 pass scaler, an alternative to mpv's built in scaling.

`altUpscale.glsl` is optimised for and only does upscaling\
`altUpscaleUnsharp.glsl` is optimised for and only does upscaling, also provides unsharp mask\
`altUpscaleHDR.glsl` is optimised for and only does upscaling; HDR version\
`altUpscaleUnsharpHDR.glsl` is optimised for and only does upscaling, also provides unsharp mask; HDR version\
`altDownscale.glsl` is optimised for and only does downscaling\
`altDownscaleUnsharp.glsl` is optimised for and only does downscaling, also provides unsharp mask\
`altDownscaleGaussian.glsl` is optimised for and only does downscaling, also provides gaussian blur\
`altDownscaleGaussianUnsharp.glsl` is optimised for and only does downscaling, also provides gaussian blur and unsharp mask

## Usage
- If you place this shader in the same folder as your `mpv.conf`, you can use it with `glsl-shaders-append="~~/FILE_NAME"`. For an example `glsl-shaders-append="~~/altUpscale.glsl"`.
- Requires `vo=gpu-next`.
- Note that defualt settings are "simbolic" only, should change them to your liking.
- Note that downscale shaders can be used for both SDR and HDR content.

## Settings

#### Kernel filter (K)
Which kernel filter to use for calculation of kernel weights. See "KERNEL FILTERS LIST" inside the shader for available kernel filters.

#### Kernel radius (R)
Kernel radius determines the kernel size, which is `ceil(2 * kernel radius)` when upsampling (upscale) or `ceil(2 * kernel radius * downscale ratio * antialiasing amount)` when downsampling (downscale).

#### Kernel blur (B)
Effectively values smaller than 1 sharpen the kernel and values larger than 1 blur the kernel, 1 is neutral or no effect. Only affects widowed sinc kernels.

#### Antiringing (AR) (Only for upscale)
Reduces ringing artifacts.

#### Antialiasing (AA) (Only for downscale)
Effectively trades between aliasing and ringing artifacts.

#### Kernel filter parameters (P1) and (P2)
Some kernel filter functions take additional parameters, they are set here. \
See references for: \
BLACKMAN - https://en.wikipedia.org/wiki/Window_function#Blackman_window \
GNW (generalized normal window) - https://ieeexplore.ieee.org/document/6638833 \
SAID - https://www.hpl.hp.com/techreports/2007/HPL-2007-179.pdf \
BCSPLINE - https://www.cs.utexas.edu/~fussell/courses/cs384g-fall2013/lectures/mitchell/Mitchell.pdf \
BICUBIC - https://en.wikipedia.org/wiki/Bicubic_interpolation

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
