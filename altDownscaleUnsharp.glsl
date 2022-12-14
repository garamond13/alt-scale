//!HOOK MAIN
//!BIND HOOKED
//!SAVE PASS0
//!WHEN OUTPUT.w OUTPUT.h * MAIN.w MAIN.h * <
//!DESC alt downscale pass0

vec4 hook() {
    return linearize(clamp(textureLod(HOOKED_raw, HOOKED_pos, 0.0), 0.0, 1.0));
}

//!HOOK MAIN
//!BIND PASS0
//!SAVE PASS1
//!HEIGHT OUTPUT.h
//!WHEN OUTPUT.w OUTPUT.h * MAIN.w MAIN.h * <
//!DESC alt downscale pass1

////////////////////////////////////////////////////////////////////////
//
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
#define NEAREST 10
#define LINEAR 11
//
////////////////////////////////////////////////////////////////////////
// USER CONFIGURABLE, PASS 1 (downscale in y axis)
//
//CAUTION! probably should use the same settings for "USER CONFIGURABLE, PASS 2" below
//
#define K LINEAR //wich kernel filter to use, see "KERNEL FILTERS LIST"
#define R 1.0 //kernel radius (integer as float, e.g. 3.0), (0.0, 10.0+]
#define B 1.0 //kernel blur, 1.0 means no effect, (0.0, 1.5+]
#define AA 1.0 //antialiasing amount, reduces aliasing, but increases ringing, (0.0, 1.0]
//
//kernel filter parameters
#define P1 0.0 //SAID: chi, BCSPLINE: B, BICUBIC: alpha
#define P2 0.0 //SAID: eta, BCSPLINE: C
//
////////////////////////////////////////////////////////////////////////

#define M_PI 3.14159265358979323846
#define M_PI_2 1.57079632679489661923
#define FLT_EPSILON 1.192092896e-07

//kernel filters
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
#elif K == SAID //source https://www.hpl.hp.com/techreports/2007/HPL-2007-179.pdf
    #define k(x) (sinc(x) * cosh(sqrt(2.0 * P2) * M_PI * P1 / (2.0 - P2) * x) * exp(-(M_PI * M_PI * P1 * P1 / ((2.0 - P2) * (2.0 - P2)) * x * x)))
#elif K == BCSPLINE
    #undef R
    #define R 2.0
    #define k(x) (x < 1.0 ? (12.0 - 9.0 * P1 - 6.0 * P2) * x * x * x + (-18.0 + 12.0 * P1 + 6.0 * P2) * x * x + (6.0 - 2.0 * P1) : (-P1 - 6.0 * P2) * x * x * x + (6.0 * P1 + 30.0 * P2) * x * x + (-12.0 * P1 - 48.0 * P2) * x + (8.0 * P1 + 24.0 * P2))
#elif K == BICUBIC
    #undef R
    #define R 2.0
    #define k(x) (x < 1.0 ? (P1 + 2.0) * x * x * x - (P1 + 3.0) * x * x + 1.0 : P1 * x * x * x - 5.0 * P1 * x * x + 8.0 * P1 * x - 4.0 * P1)
#elif K == NEAREST
    #undef R
    #define R 0.5
    #define k(x) (1.0)
#elif K == LINEAR
    #undef R
    #define R 1.0
    #define k(x) (1.0 - x)
#endif
#define get_weight(x) (x < R ? k(x) : 0.0)

//sample in y axis
vec4 hook() {
    float fcoord = fract(PASS0_pos.y * input_size.y - 0.5);
    vec2 base = PASS0_pos - fcoord * PASS0_pt * vec2(0.0, 1.0);
    float scale = (input_size.y / target_size.y) * AA;
    float r = ceil(R * scale);
    float weight;
    vec4 csum = vec4(0.0);
    float wsum = 0.0;
    for (float i = 1.0 - r; i <= r; ++i) {
        weight = get_weight(abs((i - fcoord) / scale));
        csum += textureLod(PASS0_raw, base + PASS0_pt * vec2(0.0, i), 0.0) * weight;
        wsum += weight;
    }
    return csum / wsum;
}

//!HOOK MAIN
//!BIND PASS1
//!SAVE PASS2
//!WIDTH OUTPUT.w
//!HEIGHT OUTPUT.h
//!WHEN OUTPUT.w OUTPUT.h * MAIN.w MAIN.h * <
//!DESC alt downscale pass2

////////////////////////////////////////////////////////////////////////
//
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
#define NEAREST 10
#define LINEAR 11
//
////////////////////////////////////////////////////////////////////////
// USER CONFIGURABLE, PASS 2 (downscale in x axis)
//
//CAUTION! probably should use the same settings for "USER CONFIGURABLE, PASS 1" above
//
#define K LINEAR //wich kernel filter to use, see "KERNEL FILTERS LIST"
#define R 1.0 //kernel radius (integer as float, e.g. 3.0), (0.0, 10.0+]
#define B 1.0 //kernel blur, 1.0 means no effect, (0.0, 1.5+]
#define AA 1.0 //antialiasing amount, reduces aliasing, but increases ringing, (0.0, 1.0]
//
//kernel parameters
#define P1 0.0 //SAID: chi, BCSPLINE: B, BICUBIC: alpha
#define P2 0.0 //SAID: eta, BCSPLINE: C
//
////////////////////////////////////////////////////////////////////////

#define M_PI 3.14159265358979323846
#define M_PI_2 1.57079632679489661923
#define FLT_EPSILON 1.192092896e-07

//kernel filters
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
#elif K == SAID //source https://www.hpl.hp.com/techreports/2007/HPL-2007-179.pdf
    #define k(x) (sinc(x) * cosh(sqrt(2.0 * P2) * M_PI * P1 / (2.0 - P2) * x) * exp(-(M_PI * M_PI * P1 * P1 / ((2.0 - P2) * (2.0 - P2)) * x * x)))
#elif K == BCSPLINE
    #undef R
    #define R 2.0
    #define k(x) (x < 1.0 ? (12.0 - 9.0 * P1 - 6.0 * P2) * x * x * x + (-18.0 + 12.0 * P1 + 6.0 * P2) * x * x + (6.0 - 2.0 * P1) : (-P1 - 6.0 * P2) * x * x * x + (6.0 * P1 + 30.0 * P2) * x * x + (-12.0 * P1 - 48.0 * P2) * x + (8.0 * P1 + 24.0 * P2))
#elif K == BICUBIC
    #undef R
    #define R 2.0
    #define k(x) (x < 1.0 ? (P1 + 2.0) * x * x * x - (P1 + 3.0) * x * x + 1.0 : P1 * x * x * x - 5.0 * P1 * x * x + 8.0 * P1 * x - 4.0 * P1)
#elif K == NEAREST
    #undef R
    #define R 0.5
    #define k(x) (1.0)
#elif K == LINEAR
    #undef R
    #define R 1.0
    #define k(x) (1.0 - x)
#endif
#define get_weight(x) (x < R ? k(x) : 0.0)

//sample in x axis
vec4 hook() {
    float fcoord = fract(PASS1_pos.x * input_size.x - 0.5);
    vec2 base = PASS1_pos - fcoord * PASS1_pt * vec2(1.0, 0.0);
    float scale = (input_size.x / target_size.x) * AA;
    float r = ceil(R * scale);
    float weight;
    vec4 csum = vec4(0.0);
    float wsum = 0.0;
    for (float i = 1.0 - r; i <= r; ++i) {
        weight = get_weight(abs((i - fcoord) / scale));
        csum += textureLod(PASS1_raw, base + PASS1_pt * vec2(i, 0.0), 0.0) * weight;
        wsum += weight;
    }
    return csum / wsum;
}

//!HOOK MAIN
//!BIND PASS2
//!SAVE PASS3
//!WIDTH OUTPUT.w
//!HEIGHT OUTPUT.h
//!WHEN OUTPUT.w OUTPUT.h * MAIN.w MAIN.h * <
//!DESC alt downscale pass3

////////////////////////////////////////////////////////////////////////
// USER CONFIGURABLE, PASS 3 (blur in y axis)
//
//CAUTION! probably should use the same settings for "USER CONFIGURABLE, PASS 4" below
//
#define SIGMA 1.0 //blur spread or amount, (0.0, 10+]
#define RADIUS 3.0 //kernel radius (integer as float, e.g. 3.0), (0.0, 10+]; probably should set it to ceil(3 * sigma)
//
////////////////////////////////////////////////////////////////////////

#define get_weight(x) (exp(-(x * x / (2.0 * SIGMA * SIGMA))))

vec4 hook() {
    float weight;
    vec4 csum = textureLod(PASS2_raw, PASS2_pos, 0.0);
    float wsum = 1.0;
    for(float i = 1.0; i <= RADIUS; ++i) {
        weight = get_weight(i);
        csum += (textureLod(PASS2_raw, PASS2_pos + PASS2_pt * vec2(0.0, -i), 0.0) + textureLod(PASS2_raw, PASS2_pos + PASS2_pt * vec2(0.0, i), 0.0)) * weight;
        wsum += 2.0 * weight;
    }
    return csum / wsum;
}

//!HOOK MAIN
//!BIND PASS2
//!BIND PASS3
//!WIDTH OUTPUT.w
//!HEIGHT OUTPUT.h
//!WHEN OUTPUT.w OUTPUT.h * MAIN.w MAIN.h * <
//!DESC alt downscale pass4

////////////////////////////////////////////////////////////////////////
// USER CONFIGURABLE, PASS 3 (blur in x axis and aply unsharp mask)
//
//CAUTION! probably should use the same settings for "USER CONFIGURABLE, PASS 3" above
//
#define SIGMA 1.0 //blur spread or amount, (0.0, 10+]
#define RADIUS 3.0 //kernel radius (integer as float, e.g. 3.0), (0.0, 10+]; probably should set it to ceil(3 * sigma)
//
//sharpnes
#define AMOUNT 0.5 //amount of sharpening [0.0, 10+]
//
////////////////////////////////////////////////////////////////////////

#define get_weight(x) (exp(-(x * x / (2.0 * SIGMA * SIGMA))))

vec4 hook() {
    float weight;
    vec4 csum = textureLod(PASS3_raw, PASS3_pos, 0.0);
    float wsum = 1.0;
    for(float i = 1.0; i <= RADIUS; ++i) {
        weight = get_weight(i);
        csum += (textureLod(PASS3_raw, PASS3_pos + PASS3_pt * vec2(-i, 0.0), 0.0) + textureLod(PASS3_raw, PASS3_pos + PASS3_pt * vec2(i, 0.0), 0.0)) * weight;
        wsum += 2.0 * weight;
    }
    vec4 original = textureLod(PASS2_raw, PASS2_pos, 0.0);
    return delinearize(clamp(original + (original - csum / wsum) * AMOUNT, 0.0, 1.0));
}
