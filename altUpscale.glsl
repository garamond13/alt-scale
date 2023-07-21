//!HOOK MAIN
//!BIND HOOKED
//!SAVE PASS1
//!WHEN OUTPUT.w OUTPUT.h * MAIN.w MAIN.h * >
//!DESC alt upscale pass1

////////////////////////////////////////////////////////////////////////
// USER CONFIGURABLE, PASS 1 (sigmoidize)
//
// CAUTION! probably should use the same settings for "USER CONFIGURABLE, PASS 3" below
//
//sigmoidal curve
#define C 6.5 //contrast, equivalent to mpv's --sigmoid-slope
#define M 0.75 //midpoint, equivalent to mpv's --sigmoid-center
//
////////////////////////////////////////////////////////////////////////

//based on https://github.com/ImageMagick/ImageMagick/blob/main/MagickCore/enhance.c
#define sigmoidize(rgba) (M - log(1.0 / ((1.0 / (1.0 + exp(C * (M - 1.0))) - 1.0 / (1.0 + exp(C * M))) * (rgba) + 1.0 / (1.0 + exp(C * M))) - 1.0) / C)

vec4 hook() {
    return sigmoidize(clamp(linearize(textureLod(HOOKED_raw, HOOKED_pos, 0.0) * HOOKED_mul), 0.0, 1.0));
}

//!HOOK MAIN
//!BIND PASS1
//!SAVE PASS2
//!HEIGHT OUTPUT.h
//!WHEN OUTPUT.w OUTPUT.h * MAIN.w MAIN.h * >
//!DESC alt upscale pass2

////////////////////////////////////////////////////////////////////////
// KERNEL FUNCTIONS LIST
//
#define LANCZOS 1
#define COSINE 2
#define GARAMOND 3
#define BLACKMAN 4
#define GNW 5
#define SAID 6
#define FSR 7
#define BCSPLINE 8
//
////////////////////////////////////////////////////////////////////////
// USER CONFIGURABLE, PASS 2 (upsample in y axis)
//
// CAUTION! probably should use the same settings for "USER CONFIGURABLE, PASS 3" below
//
#define K LANCZOS //kernel function, see "KERNEL FUNCTIONS LIST"
#define R 2.0 //kernel radius, (0.0, 10.0+]
#define B 1.0 //kernel blur, 1.0 means no effect, (0.0, 1.5+]
#define AR 1.0 //antiringing strenght, [0.0, 1.0]
//
//kernel function parameters
#define P1 0.0 //COSINE: n, GARAMOND: n, BLACKMAN: a, GNW: s, SAID: chi, FSR: b, BCSPLINE: B
#define P2 0.0 //GARAMOND: m, BLACKMAN: n, GNW: n, SAID: eta, FSR: c, BCSPLINE: C
//
////////////////////////////////////////////////////////////////////////

#define M_PI 3.1415927
#define M_PI_2 1.5707963
#define EPS 1e-6

#define sinc(x) ((x) < EPS ? M_PI / B : sin(M_PI / B * (x)) / (x))

#if K == LANCZOS
    #define k(x) (sinc(x) * ((x) < EPS ? M_PI / R : sin(M_PI / R * (x)) / (x)))
#elif K == COSINE
    #define k(x) (sinc(x) * pow(cos(M_PI_2 / R * (x)), P1))
#elif K == GARAMOND
    #define k(x) (sinc(x) * pow(1.0 - pow((x) / R, P1), P2))
#elif K == BLACKMAN
    #define k(x) (sinc(x) * pow((1.0 - P1) / 2.0 + 0.5 * cos(M_PI / R * (x)) + P1 / 2.0 * cos(2.0 * M_PI / R * (x)), P2))
#elif K == GNW
    #define k(x) (sinc(x) * exp(-pow((x) / P1, P2)))
#elif K == SAID
    #define k(x) (sinc(x) * cosh(sqrt(2.0 * P2) * M_PI * P1 / (2.0 - P2) * (x)) * exp(-M_PI * M_PI * P1 * P1 / ((2.0 - P2) * (2.0 - P2)) * (x) * (x)))
#elif K == FSR
    #undef R
    #define R 2.0
    #define k(x) ((1.0 / (2.0 * P1 - P1 * P1) * (P1 / (P2 * P2) * (x) * (x) - 1.0) * (P1 / (P2 * P2) * (x) * (x) - 1.0) - (1.0 / (2.0 * P1 - P1 * P1) - 1.0)) * (0.25 * (x) * (x) - 1.0) * (0.25 * (x) * (x) - 1.0))
#elif K == BCSPLINE
    #undef R
    #define R 2.0
    #define k(x) ((x) < 1.0 ? (12.0 - 9.0 * P1 - 6.0 * P2) * (x) * (x) * (x) + (-18.0 + 12.0 * P1 + 6.0 * P2) * (x) * (x) + (6.0 - 2.0 * P1) : (-P1 - 6.0 * P2) * (x) * (x) * (x) + (6.0 * P1 + 30.0 * P2) * (x) * (x) + (-12.0 * P1 - 48.0 * P2) * (x) + (8.0 * P1 + 24.0 * P2))
#endif

#define get_weight(x) ((x) < R ? k(x) : 0.0)

vec4 hook() {
    float fcoord = fract(PASS1_pos.y * input_size.y - 0.5);
    vec2 base = PASS1_pos - fcoord * PASS1_pt * vec2(0.0, 1.0);
    vec4 color;
    float weight;
    vec4 csum = vec4(0.0);
    float wsum = 0.0;
    vec4 low = vec4(1e9);
    vec4 high = vec4(-1e9);
    for (float i = 1.0 - ceil(R); i <= ceil(R); ++i) {
        weight = get_weight(abs(i - fcoord));
        color = textureLod(PASS1_raw, base + PASS1_pt * vec2(0.0, i), 0.0) * PASS1_mul;
        csum += color * weight;
        wsum += weight;
        if (AR > 0.0 && i >= 0.0 && i <= 1.0) {
            low = min(low, color);
            high = max(high, color);
        }
    }
    csum /= wsum;
    if (AR > 0.0)
        csum = mix(csum, clamp(csum, low, high), AR);
    return csum;
}

//!HOOK MAIN
//!BIND PASS2
//!WIDTH OUTPUT.w
//!HEIGHT OUTPUT.h
//!WHEN OUTPUT.w OUTPUT.h * MAIN.w MAIN.h * >
//!DESC alt upscale pass3

////////////////////////////////////////////////////////////////////////
// KERNEL FUNCTIONS LIST
//
#define LANCZOS 1
#define COSINE 2
#define GARAMOND 3
#define BLACKMAN 4
#define GNW 5
#define SAID 6
#define FSR 7
#define BCSPLINE 8
//
////////////////////////////////////////////////////////////////////////
// USER CONFIGURABLE, PASS 3 (upsample in x axis and desigmoidize)
//
// CAUTION! probably should use the same settings for "USER CONFIGURABLE, PASS 2" above
//
#define K LANCZOS //kernel function, see "KERNEL FUNCTIONS LIST"
#define R 2.0 //kernel radius, (0.0, 10.0+]
#define B 1.0 //kernel blur, 1.0 means no effect, (0.0, 1.5+]
#define AR 1.0 //antiringing strenght, [0.0, 1.0]
//
//kernel function parameters
#define P1 0.0 //COSINE: n, GARAMOND: n, BLACKMAN: a, GNW: s, SAID: chi, FSR: b, BCSPLINE: B
#define P2 0.0 //GARAMOND: m, BLACKMAN: n, GNW: n, SAID: eta, FSR: c, BCSPLINE: C
//
// CAUTION! probably should use the same settings for "USER CONFIGURABLE, PASS 1" above
//
#define C 6.5 //contrast, equivalent to mpv's --sigmoid-slope
#define M 0.75 //midpoint, equivalent to mpv's --sigmoid-center
//
////////////////////////////////////////////////////////////////////////

#define M_PI 3.1415927
#define M_PI_2 1.5707963
#define EPS 1e-6

#define sinc(x) ((x) < EPS ? M_PI / B : sin(M_PI / B * (x)) / (x))

#if K == LANCZOS
    #define k(x) (sinc(x) * ((x) < EPS ? M_PI / R : sin(M_PI / R * (x)) / (x)))
#elif K == COSINE
    #define k(x) (sinc(x) * pow(cos(M_PI_2 / R * (x)), P1))
#elif K == GARAMOND
    #define k(x) (sinc(x) * pow(1.0 - pow((x) / R, P1), P2))
#elif K == BLACKMAN
    #define k(x) (sinc(x) * pow((1.0 - P1) / 2.0 + 0.5 * cos(M_PI / R * (x)) + P1 / 2.0 * cos(2.0 * M_PI / R * (x)), P2))
#elif K == GNW
    #define k(x) (sinc(x) * exp(-pow((x) / P1, P2)))
#elif K == SAID
    #define k(x) (sinc(x) * cosh(sqrt(2.0 * P2) * M_PI * P1 / (2.0 - P2) * (x)) * exp(-M_PI * M_PI * P1 * P1 / ((2.0 - P2) * (2.0 - P2)) * (x) * (x)))
#elif K == FSR
    #undef R
    #define R 2.0
    #define k(x) ((1.0 / (2.0 * P1 - P1 * P1) * (P1 / (P2 * P2) * (x) * (x) - 1.0) * (P1 / (P2 * P2) * (x) * (x) - 1.0) - (1.0 / (2.0 * P1 - P1 * P1) - 1.0)) * (0.25 * (x) * (x) - 1.0) * (0.25 * (x) * (x) - 1.0))
#elif K == BCSPLINE
    #undef R
    #define R 2.0
    #define k(x) ((x) < 1.0 ? (12.0 - 9.0 * P1 - 6.0 * P2) * (x) * (x) * (x) + (-18.0 + 12.0 * P1 + 6.0 * P2) * (x) * (x) + (6.0 - 2.0 * P1) : (-P1 - 6.0 * P2) * (x) * (x) * (x) + (6.0 * P1 + 30.0 * P2) * (x) * (x) + (-12.0 * P1 - 48.0 * P2) * (x) + (8.0 * P1 + 24.0 * P2))
#endif

#define get_weight(x) ((x) < R ? k(x) : 0.0)

//based on https://github.com/ImageMagick/ImageMagick/blob/main/MagickCore/enhance.c
#define desigmoidize(rgba) (1.0 / (1.0 + exp(C * (M - (rgba)))) - 1.0 / (1.0 + exp(C * M))) / ( 1.0 / (1.0 + exp(C * (M - 1.0))) - 1.0 / (1.0 + exp(C * M)))

vec4 hook() {
    float fcoord = fract(PASS2_pos.x * input_size.x - 0.5);
    vec2 base = PASS2_pos - fcoord * PASS2_pt * vec2(1.0, 0.0);
    vec4 color;
    float weight;
    vec4 csum = vec4(0.0);
    float wsum = 0.0;
    vec4 low = vec4(1e9);
    vec4 high = vec4(-1e9);
    for (float i = 1.0 - ceil(R); i <= ceil(R); ++i) {
        weight = get_weight(abs(i - fcoord));
        color = textureLod(PASS2_raw, base + PASS2_pt * vec2(i, 0.0), 0.0) * PASS2_mul;
        csum += color * weight;
        wsum += weight;
        if (AR > 0.0 && i >= 0.0 && i <= 1.0) {
            low = min(low, color);
            high = max(high, color);
        }
    }
    csum /= wsum;
    if (AR > 0.0)
        csum = mix(csum, clamp(csum, low, high), AR);
    return delinearize(desigmoidize(csum));
}
