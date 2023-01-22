//!HOOK MAIN
//!BIND HOOKED
//!SAVE PASS0
//!WHEN OUTPUT.w OUTPUT.h * MAIN.w MAIN.h * >
//!DESC alt upscale pass1

////////////////////////////////////////////////////////////////////////
// KERNEL FILTERS LIST
//
#define LANCZOS 1
#define COSINE 2
#define HANN 3
#define HAMMING 4
#define BLACKMAN 5
#define WELCH 6
#define SAID 7
#define BCSPLINE 8
#define BICUBIC 9
//
////////////////////////////////////////////////////////////////////////
// USER CONFIGURABLE, PASS 1 (upsample in y axis)
//
// CAUTION! probably should use the same settings for "USER CONFIGURABLE, PASS 2" below
//
#define K LANCZOS //kernel filter, see "KERNEL FILTERS LIST"
#define R 2.0 //kernel radius, (0.0, 10.0+]
#define B 1.0 //kernel blur, 1.0 means no effect, (0.0, 1.5+]
#define AR 0.0 //antiringing strenght, [0.0, 1.0]
//
//kernel parameters
#define P1 0.0 //SAID: chi, BCSPLINE: B, BICUBIC: alpha
#define P2 0.0 //SAID: eta, BCSPLINE: C
//
////////////////////////////////////////////////////////////////////////

#define M_PI 3.14159265358979323846
#define M_PI_2 1.57079632679489661923
#define FLT_EPSILON 1.192092896e-07

#define sinc(x) (x < FLT_EPSILON ? M_PI : sin(M_PI / B * x) * B / x)

#if K == LANCZOS
    #define k(x) (sinc(x) * (x < FLT_EPSILON ? M_PI : sin(M_PI / R * x) * R / x))
#elif K == COSINE
    #define k(x) (sinc(x) * cos(M_PI_2 / R * x))
#elif K == HANN
    #define k(x) (sinc(x) * (0.5 + 0.5 * cos(M_PI / R * x)))
#elif K == HAMMING
    #define k(x) (sinc(x) * (0.54 + 0.46 * cos(M_PI / R * x)))
#elif K == BLACKMAN
    #define k(x) (sinc(x) * (0.42 + 0.5 * cos(M_PI / R * x) + 0.08 * cos(2.0 * M_PI / R * x)))
#elif K == WELCH
    #define k(x) (sinc(x) * (1.0 - x * x / (R * R)))
#elif K == SAID
    #define k(x) (sinc(x) * cosh(sqrt(2.0 * P2) * M_PI * P1 / (2.0 - P2) * x) * exp(-M_PI * M_PI * P1 * P1 / ((2.0 - P2) * (2.0 - P2)) * x * x))
#elif K == BCSPLINE
    #undef R
    #define R 2.0
    #define k(x) (x < 1.0 ? (12.0 - 9.0 * P1 - 6.0 * P2) * x * x * x + (-18.0 + 12.0 * P1 + 6.0 * P2) * x * x + (6.0 - 2.0 * P1) : (-P1 - 6.0 * P2) * x * x * x + (6.0 * P1 + 30.0 * P2) * x * x + (-12.0 * P1 - 48.0 * P2) * x + (8.0 * P1 + 24.0 * P2))
#elif K == BICUBIC
    #undef R
    #define R 2.0
    #define k(x) (x < 1.0 ? (P1 + 2.0) * x * x * x - (P1 + 3.0) * x * x + 1.0 : P1 * x * x * x - 5.0 * P1 * x * x + 8.0 * P1 * x - 4.0 * P1)
#endif

#define get_weight(x) (x < R ? k(x) : 0.0)

vec4 hook() {
    float fcoord = fract(HOOKED_pos.y * input_size.y - 0.5);
    vec2 base = HOOKED_pos - fcoord * HOOKED_pt * vec2(0.0, 1.0);
    vec4 color;
    float weight;
    vec4 csum = vec4(0.0);
    float wsum = 0.0;
    vec4 low = vec4(1e9);
    vec4 high = vec4(-1e9);
    for (float i = 1.0 - ceil(R); i <= ceil(R); ++i) {
        weight = get_weight(abs(i - fcoord));
        color = textureLod(HOOKED_raw, base + HOOKED_pt * vec2(0.0, i), 0.0) * HOOKED_mul;
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
//!BIND PASS0
//!WIDTH OUTPUT.w
//!HEIGHT OUTPUT.h
//!WHEN OUTPUT.w OUTPUT.h * MAIN.w MAIN.h * >
//!DESC alt upscale pass2

////////////////////////////////////////////////////////////////////////
// KERNEL FILTERS LIST
//
#define LANCZOS 1
#define COSINE 2
#define HANN 3
#define HAMMING 4
#define BLACKMAN 5
#define WELCH 6
#define SAID 7
#define BCSPLINE 8
#define BICUBIC 9
//
////////////////////////////////////////////////////////////////////////
// USER CONFIGURABLE, PASS 2 (upsample in x axis and desigmoidize)
//
// CAUTION! probably should use the same settings for "USER CONFIGURABLE, PASS 1" above
//
#define K LANCZOS //kernel filter, see "KERNEL FILTERS LIST"
#define R 2.0 //kernel radius, (0.0, 10.0+]
#define B 1.0 //kernel blur, 1.0 means no effect, (0.0, 1.5+]
#define AR 0.0 //antiringing strenght, [0.0, 1.0]
//
//kernel parameters
#define P1 0.0 //SAID: chi, BCSPLINE: B, BICUBIC: alpha
#define P2 0.0 //SAID: eta, BCSPLINE: C
//
////////////////////////////////////////////////////////////////////////

#define M_PI 3.14159265358979323846
#define M_PI_2 1.57079632679489661923
#define FLT_EPSILON 1.192092896e-07

#define sinc(x) (x < FLT_EPSILON ? M_PI : sin(M_PI / B * x) * B / x)

#if K == LANCZOS
    #define k(x) (sinc(x) * (x < FLT_EPSILON ? M_PI : sin(M_PI / R * x) * R / x))
#elif K == COSINE
    #define k(x) (sinc(x) * cos(M_PI_2 / R * x))
#elif K == HANN
    #define k(x) (sinc(x) * (0.5 + 0.5 * cos(M_PI / R * x)))
#elif K == HAMMING
    #define k(x) (sinc(x) * (0.54 + 0.46 * cos(M_PI / R * x)))
#elif K == BLACKMAN
    #define k(x) (sinc(x) * (0.42 + 0.5 * cos(M_PI / R * x) + 0.08 * cos(2.0 * M_PI / R * x)))
#elif K == WELCH
    #define k(x) (sinc(x) * (1.0 - x * x / (R * R)))
#elif K == SAID
    #define k(x) (sinc(x) * cosh(sqrt(2.0 * P2) * M_PI * P1 / (2.0 - P2) * x) * exp(-M_PI * M_PI * P1 * P1 / ((2.0 - P2) * (2.0 - P2)) * x * x))
#elif K == BCSPLINE
    #undef R
    #define R 2.0
    #define k(x) (x < 1.0 ? (12.0 - 9.0 * P1 - 6.0 * P2) * x * x * x + (-18.0 + 12.0 * P1 + 6.0 * P2) * x * x + (6.0 - 2.0 * P1) : (-P1 - 6.0 * P2) * x * x * x + (6.0 * P1 + 30.0 * P2) * x * x + (-12.0 * P1 - 48.0 * P2) * x + (8.0 * P1 + 24.0 * P2))
#elif K == BICUBIC
    #undef R
    #define R 2.0
    #define k(x) (x < 1.0 ? (P1 + 2.0) * x * x * x - (P1 + 3.0) * x * x + 1.0 : P1 * x * x * x - 5.0 * P1 * x * x + 8.0 * P1 * x - 4.0 * P1)
#endif

#define get_weight(x) (x < R ? k(x) : 0.0)

vec4 hook() {
    float fcoord = fract(PASS0_pos.x * input_size.x - 0.5);
    vec2 base = PASS0_pos - fcoord * PASS0_pt * vec2(1.0, 0.0);
    vec4 color;
    float weight;
    vec4 csum = vec4(0.0);
    float wsum = 0.0;
    vec4 low = vec4(1e9);
    vec4 high = vec4(-1e9);
    for (float i = 1.0 - ceil(R); i <= ceil(R); ++i) {
        weight = get_weight(abs(i - fcoord));
        color = textureLod(PASS0_raw, base + PASS0_pt * vec2(i, 0.0), 0.0) * PASS0_mul;
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
