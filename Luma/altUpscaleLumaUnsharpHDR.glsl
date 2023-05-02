//!HOOK LUMA
//!BIND HOOKED
//!SAVE PASS1
//!HEIGHT OUTPUT.h
//!WHEN OUTPUT.w OUTPUT.h * LUMA.w LUMA.h * >
//!DESC alt upscale luma pass1

////////////////////////////////////////////////////////////////////////
// KERNEL FUNCTIONS LIST
//
#define LANCZOS 1
#define GARAMOND 2
#define COSINE 3
#define BLACKMAN 4
#define GNW 5
#define SAID 6
#define FSR 7
#define BCSPLINE 8
//
////////////////////////////////////////////////////////////////////////
// USER CONFIGURABLE, PASS 1 (upsample in y axis)
//
// CAUTION! probably should use the same settings for "USER CONFIGURABLE, PASS 2" below
//
#define K LANCZOS //kernel function, see "KERNEL FUNCTIONS LIST"
#define R 2.0 //kernel radius, (0.0, 10.0+]
#define B 1.0 //kernel blur, 1.0 means no effect, (0.0, 1.5+]
#define AR 1.0 //antiringing strenght, [0.0, 1.0]
//
//kernel function parameters
#define P1 0.0 //GARAMOND: n, COSINE: n, BLACKMAN: a, GNW: s, SAID: chi, FSR: b, BCSPLINE: B
#define P2 0.0 //GNW: n, SAID: eta, FSR: c, BCSPLINE: C
//
////////////////////////////////////////////////////////////////////////

#define M_PI 3.14159265358979323846
#define M_PI_2 1.57079632679489661923
#define EPSILON 1.192093e-7

#define sinc(x) (x < EPSILON ? M_PI : sin(M_PI / B * x) * B / x)

#if K == LANCZOS
    #define k(x) (sinc(x) * (x < EPSILON ? M_PI : sin(M_PI / R * x) * R / x))
#elif K == GARAMOND
    #define k(x) (sinc(x) * (1.0 - pow(x / R, P1)))
#elif K == COSINE
    #define k(x) (sinc(x) * pow(cos(M_PI_2 / R * x), P1))
#elif K == BLACKMAN
    #define k(x) (sinc(x) * ((1.0 - P1) / 2.0 + 0.5 * cos(M_PI / R * x) + P1 / 2.0 * cos(2.0 * M_PI / R * x)))
#elif K == GNW
    #define k(x) (sinc(x) * exp(-pow(x / P1, P2)))
#elif K == SAID
    #define k(x) (sinc(x) * cosh(sqrt(2.0 * P2) * M_PI * P1 / (2.0 - P2) * x) * exp(-M_PI * M_PI * P1 * P1 / ((2.0 - P2) * (2.0 - P2)) * x * x))
#elif K == FSR
    #undef R
    #define R 2.0
    #define k(x) ((1.0 / (2.0 * P1 - P1 * P1) * (P1 / (P2 * P2) * x * x - 1.0) * (P1 / (P2 * P2) * x * x - 1.0) - (1.0 / (2.0 * P1 - P1 * P1) - 1.0)) * (0.25 * x * x - 1.0) * (0.25 * x * x - 1.0))
#elif K == BCSPLINE
    #undef R
    #define R 2.0
    #define k(x) (x < 1.0 ? (12.0 - 9.0 * P1 - 6.0 * P2) * x * x * x + (-18.0 + 12.0 * P1 + 6.0 * P2) * x * x + (6.0 - 2.0 * P1) : (-P1 - 6.0 * P2) * x * x * x + (6.0 * P1 + 30.0 * P2) * x * x + (-12.0 * P1 - 48.0 * P2) * x + (8.0 * P1 + 24.0 * P2))
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

//!HOOK LUMA
//!BIND PASS1
//!SAVE PASS2
//!WIDTH OUTPUT.w
//!HEIGHT OUTPUT.h
//!WHEN OUTPUT.w OUTPUT.h * LUMA.w LUMA.h * >
//!DESC alt upscale luma pass2

////////////////////////////////////////////////////////////////////////
// KERNEL FUNCTIONS LIST
//
#define LANCZOS 1
#define GARAMOND 2
#define COSINE 3
#define BLACKMAN 4
#define GNW 5
#define SAID 6
#define FSR 7
#define BCSPLINE 8
//
////////////////////////////////////////////////////////////////////////
// USER CONFIGURABLE, PASS 2 (upsample in x axis and desigmoidize)
//
// CAUTION! probably should use the same settings for "USER CONFIGURABLE, PASS 1" above
//
#define K LANCZOS //kernel function, see "KERNEL FUNCTIONS LIST"
#define R 2.0 //kernel radius, (0.0, 10.0+]
#define B 1.0 //kernel blur, 1.0 means no effect, (0.0, 1.5+]
#define AR 1.0 //antiringing strenght, [0.0, 1.0]
//
//kernel function parameters
#define P1 0.0 //GARAMOND: n, COSINE: n, BLACKMAN: a, GNW: s, SAID: chi, FSR: b, BCSPLINE: B
#define P2 0.0 //GNW: n, SAID: eta, FSR: c, BCSPLINE: C
//
////////////////////////////////////////////////////////////////////////

#define M_PI 3.14159265358979323846
#define M_PI_2 1.57079632679489661923
#define EPSILON 1.192093e-7

#define sinc(x) (x < EPSILON ? M_PI : sin(M_PI / B * x) * B / x)

#if K == LANCZOS
    #define k(x) (sinc(x) * (x < EPSILON ? M_PI : sin(M_PI / R * x) * R / x))
#elif K == GARAMOND
    #define k(x) (sinc(x) * (1.0 - pow(x / R, P1)))
#elif K == COSINE
    #define k(x) (sinc(x) * pow(cos(M_PI_2 / R * x), P1))
#elif K == BLACKMAN
    #define k(x) (sinc(x) * ((1.0 - P1) / 2.0 + 0.5 * cos(M_PI / R * x) + P1 / 2.0 * cos(2.0 * M_PI / R * x)))
#elif K == GNW
    #define k(x) (sinc(x) * exp(-pow(x / P1, P2)))
#elif K == SAID
    #define k(x) (sinc(x) * cosh(sqrt(2.0 * P2) * M_PI * P1 / (2.0 - P2) * x) * exp(-M_PI * M_PI * P1 * P1 / ((2.0 - P2) * (2.0 - P2)) * x * x))
#elif K == FSR
    #undef R
    #define R 2.0
    #define k(x) ((1.0 / (2.0 * P1 - P1 * P1) * (P1 / (P2 * P2) * x * x - 1.0) * (P1 / (P2 * P2) * x * x - 1.0) - (1.0 / (2.0 * P1 - P1 * P1) - 1.0)) * (0.25 * x * x - 1.0) * (0.25 * x * x - 1.0))
#elif K == BCSPLINE
    #undef R
    #define R 2.0
    #define k(x) (x < 1.0 ? (12.0 - 9.0 * P1 - 6.0 * P2) * x * x * x + (-18.0 + 12.0 * P1 + 6.0 * P2) * x * x + (6.0 - 2.0 * P1) : (-P1 - 6.0 * P2) * x * x * x + (6.0 * P1 + 30.0 * P2) * x * x + (-12.0 * P1 - 48.0 * P2) * x + (8.0 * P1 + 24.0 * P2))
#endif

#define get_weight(x) (x < R ? k(x) : 0.0)

vec4 hook() {
    float fcoord = fract(PASS1_pos.x * input_size.x - 0.5);
    vec2 base = PASS1_pos - fcoord * PASS1_pt * vec2(1.0, 0.0);
    vec4 color;
    float weight;
    vec4 csum = vec4(0.0);
    float wsum = 0.0;
    vec4 low = vec4(1e9);
    vec4 high = vec4(-1e9);
    for (float i = 1.0 - ceil(R); i <= ceil(R); ++i) {
        weight = get_weight(abs(i - fcoord));
        color = textureLod(PASS1_raw, base + PASS1_pt * vec2(i, 0.0), 0.0) * PASS1_mul;
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

//!HOOK LUMA
//!BIND PASS2
//!SAVE PASS3
//!WIDTH OUTPUT.w
//!HEIGHT OUTPUT.h
//!WHEN OUTPUT.w OUTPUT.h * LUMA.w LUMA.h * >
//!DESC alt upscale luma pass3

vec4 hook() {
    return linearize(textureLod(PASS2_raw, PASS2_pos, 0.0) * PASS2_mul);
}

//!HOOK LUMA
//!BIND PASS3
//!SAVE PASS4
//!WIDTH OUTPUT.w
//!HEIGHT OUTPUT.h
//!WHEN OUTPUT.w OUTPUT.h * LUMA.w LUMA.h * >
//!DESC alt upscale luma pass4

////////////////////////////////////////////////////////////////////////
// USER CONFIGURABLE, PASS 4 (blur in y axis)
//
// CAUTION! probably should use the same settings for "USER CONFIGURABLE, PASS 5" below
//
#define S 1.0 //blur spread or amount, (0.0, 10+]
#define R 3.0 //kernel radius (integer as float, e.g. 3.0), (0.0, 10+]; probably should set it to ceil(3 * S)
//
////////////////////////////////////////////////////////////////////////

#define get_weight(x) (exp(-x * x / (2.0 * S * S)))

vec4 hook() {
    float weight;
    vec4 csum = textureLod(PASS3_raw, PASS3_pos, 0.0) * PASS3_mul;
    float wsum = 1.0;
    for(float i = 1.0; i <= R; ++i) {
        weight = get_weight(i);
        csum += (textureLod(PASS3_raw, PASS3_pos + PASS3_pt * vec2(0.0, -i), 0.0) + textureLod(PASS3_raw, PASS3_pos + PASS3_pt * vec2(0.0, i), 0.0)) * PASS3_mul * weight;
        wsum += 2.0 * weight;
    }
    return csum / wsum;
}

//!HOOK LUMA
//!BIND PASS3
//!BIND PASS4
//!WIDTH OUTPUT.w
//!HEIGHT OUTPUT.h
//!WHEN OUTPUT.w OUTPUT.h * LUMA.w LUMA.h * >
//!DESC alt upscale luma pass5

////////////////////////////////////////////////////////////////////////
// USER CONFIGURABLE, PASS 5 (blur in x axis and apply unsharp mask)
//
// CAUTION! probably should use the same settings for "USER CONFIGURABLE, PASS 4" above
//
#define S 1.0 //blur spread or amount, (0.0, 10+]
#define R 3.0 //kernel radius (integer as float, e.g. 3.0), (0.0, 10+]; probably should set it to ceil(3 * S)
//
//sharpnes
#define A 0.5 //amount of sharpening [0.0, 10+]
//
////////////////////////////////////////////////////////////////////////

#define get_weight(x) (exp(-x * x / (2.0 * S * S)))

vec4 hook() {
    float weight;
    vec4 csum = textureLod(PASS4_raw, PASS4_pos, 0.0) * PASS4_mul;
    float wsum = 1.0;
    for(float i = 1.0; i <= R; ++i) {
        weight = get_weight(i);
        csum += (textureLod(PASS4_raw, PASS4_pos + PASS4_pt * vec2(-i, 0.0), 0.0) + textureLod(PASS4_raw, PASS4_pos + PASS4_pt * vec2(i, 0.0), 0.0)) * PASS4_mul * weight;
        wsum += 2.0 * weight;
    }
    vec4 original = textureLod(PASS3_raw, PASS3_pos, 0.0) * PASS3_mul;
    return delinearize(original + (original - csum / wsum) * A);
}
