# Alt scale
Alt scale is a mpv shader. A 2 pass scaler, an alternative to mpv's built in scaling.

`altUpscale.glsl` is optimised for and only does upscaling\
`altDownscale.glsl` is optimised for and only does downscaling

## Usage
If you place this shader in the same folder as your `mpv.conf`, you can use it with `glsl-shaders-append="~~/altUpscale.glsl"` or `glsl-shaders-append="~~/altDownscale.glsl"`

## Settings
### Kernel filter (K)
Which kernel filter function to use for calculation of kernel weights.

### Kernel radius (R)
Kernel radius determines the kernel size, which is (2 * kernel radius) when upscaling or (2 * kernel radius * downscale ratio * antialiasing amount) when downscaling.

### Antiringing (AR)
Only for upscale. Reduces ringing artifacts.

### Antialiasing (AA)
Only for downscale. Effectively trades between aliasing and ringing artifacts.

### Kernel filter parameters (P1) and (P2)
Some kernel filter functions take additional parameters, they are set here.

### Sigmoidal curve settings (CONTRAST) and (MIDPOINT)
`CONTRAST` is equivalent to mpv's `--sigmoid-slope` and `MIDPOINT` is equivalent to mpv's `--sigmoid-center`.
