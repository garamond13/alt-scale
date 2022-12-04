//!HOOK MAIN
//!BIND HOOKED
//!SAVE PASS0
//!WHEN OUTPUT.w OUTPUT.h * MAIN.w MAIN.h * <
//!DESC alt downscale pass0

vec4 hook() {
    return linearize(textureLod(HOOKED_raw, HOOKED_pos, 0.0));
}

//!HOOK MAIN
//!BIND PASS0
//!SAVE PASS1
//!WHEN OUTPUT.w OUTPUT.h * MAIN.w MAIN.h * <
//!DESC alt downscale pass1

////////////////////////////////////////////////////////////////////////
// USER CONFIGURABLE, PASS 1 (blur in y axis)
//
//CAUTION! probably should use the same settings for "USER CONFIGURABLE, PASS 2" below
//
#define SIGMA 1.0 //blur spread or amount, (0.0, 10+]
#define RADIUS 3.0 //kernel radius (integer as float, e.g. 3.0), (0.0, 10+]; probably should set it to ceil(3 * sigma)
//
////////////////////////////////////////////////////////////////////////

#define get_weight(x) (exp(-(x * x / (2.0 * SIGMA * SIGMA))))

vec4 hook() {
    float weight = get_weight(0.0);
    vec4 csum = textureLod(PASS0_raw, PASS0_pos, 0.0) * weight;
    float wsum = weight;
    for(float i = 1.0; i <= RADIUS; ++i) {
        weight = get_weight(i);
        csum += textureLod(PASS0_raw, PASS0_pos + PASS0_pt * vec2(0.0, -i), 0.0) * weight;
        csum += textureLod(PASS0_raw, PASS0_pos + PASS0_pt * vec2(0.0, i), 0.0) * weight;
        wsum += 2.0 * weight;
    }
    return csum / wsum;
}

//!HOOK MAIN
//!BIND PASS1
//!SAVE PASS2
//!WHEN OUTPUT.w OUTPUT.h * MAIN.w MAIN.h * <
//!DESC alt downscale pass2

////////////////////////////////////////////////////////////////////////
// USER CONFIGURABLE, PASS 2 (blur in x axis)
//
//CAUTION! probably should use the same settings for "USER CONFIGURABLE, PASS 1" above
//
#define SIGMA 1.0 //blur spread or amount, (0.0, 10+]
#define RADIUS 3.0 //kernel radius (integer as float, e.g. 3.0), (0.0, 10+]; probably should set it to ceil(3 * sigma)
//
////////////////////////////////////////////////////////////////////////

#define get_weight(x) (exp(-(x * x / (2.0 * SIGMA * SIGMA))))

vec4 hook() {
    float weight = get_weight(0.0);
    vec4 csum = textureLod(PASS1_raw, PASS1_pos, 0.0) * weight;
    float wsum = weight;
    for(float i = 1.0; i <= RADIUS; ++i) {
        weight = get_weight(i);
        csum += textureLod(PASS1_raw, PASS1_pos + PASS1_pt * vec2(-i, 0.0), 0.0) * weight;
        csum += textureLod(PASS1_raw, PASS1_pos + PASS1_pt * vec2(i, 0.0), 0.0) * weight;
        wsum += 2.0 * weight;
    }
    return csum / wsum;
}

//!HOOK MAIN
//!BIND PASS2
//!SAVE PASS3
//!HEIGHT OUTPUT.h
//!WHEN OUTPUT.w OUTPUT.h * MAIN.w MAIN.h * <
//!DESC alt downscale pass3

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
// USER CONFIGURABLE, PASS 3 (downscale in y axis)
//
//CAUTION! probably should use the same settings for "USER CONFIGURABLE, PASS 4" below
//
#define K HAMMING //wich kernel filter to use, see "KERNEL FILTERS LIST"
#define R 3.0 //kernel radius (integer as float, e.g. 3.0), (0.0, 10.0+]
#define AA 1.0 //antialiasing amount, reduces aliasing, but increases ringing, (0.0, 1.0]
//
//kernel filter parameters
#define P1 0.0 //SAID: chi, BCSPLINE: B, BICUBIC: alpha
#define P2 0.0 //SAID: eta, BCSPLINE: C
//
////////////////////////////////////////////////////////////////////////

#define M_PI 3.1415927 //pi
#define M_PI_2 1.5707963 //pi/2

//kernel filters
#define sinc(x) (x < 1e-7 ? 1.0 : sin(M_PI * x) / (M_PI * x))
#if K == LANCZOS
    #define k(x) (sinc(x) * sinc(x / R))
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
    #define k(x) (x < 1.0 ? ((12.0 - 9.0 * P1 - 6.0 * P2) * x * x * x + (-18.0 + 12.0 * P1 + 6.0 * P2) * x * x + (6.0 - 2.0 * P1)) / 6.0 : ((-P1 - 6.0 * P2) * x * x * x + (6.0 * P1 + 30.0 * P2) * x * x + (-12.0 * P1 - 48.0 * P2) * x + (8.0 * P1 + 24.0 * P2)) / 6.0)
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
    float fcoord = fract(PASS2_pos.y * input_size.y - 0.5);
    vec2 base = PASS2_pos - fcoord * PASS2_pt * vec2(0.0, 1.0);
    float scale = (input_size.y / target_size.y) * AA;
    float r = ceil(R * scale);
    float weight;
    vec4 csum = vec4(0.0);
    float wsum = 0.0;
    for (float i = 1.0 - r; i <= r; ++i) {
        weight = get_weight(abs((i - fcoord) / scale));
        csum += textureLod(PASS2_raw, base + PASS2_pt * vec2(0.0, i), 0.0) * weight;
        wsum += weight;
    }
    return csum / wsum;
}

//!HOOK MAIN
//!BIND PASS3
//!SAVE PASS4
//!WIDTH OUTPUT.w
//!HEIGHT OUTPUT.h
//!WHEN OUTPUT.w OUTPUT.h * MAIN.w MAIN.h * <
//!DESC alt downscale pass4

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
// USER CONFIGURABLE, PASS 4 (downscale in x axis)
//
//CAUTION! probably should use the same settings for "USER CONFIGURABLE, PASS 3" above
//
#define K HAMMING //wich kernel filter to use, see "KERNEL FILTERS LIST"
#define R 3.0 //kernel radius (integer as float, e.g. 3.0), (0.0, 10.0+]
#define AA 1.0 //antialiasing amount, reduces aliasing, but increases ringing, (0.0, 1.0]
//
//kernel parameters
#define P1 0.0 //SAID: chi, BCSPLINE: B, BICUBIC: alpha
#define P2 0.0 //SAID: eta, BCSPLINE: C
//
////////////////////////////////////////////////////////////////////////

#define M_PI 3.1415927 //pi
#define M_PI_2 1.5707963 //pi/2

//kernel filters
#define sinc(x) (x < 1e-7 ? 1.0 : sin(M_PI * x) / (M_PI * x))
#if K == LANCZOS
    #define k(x) (sinc(x) * sinc(x / R))
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
    #define k(x) (x < 1.0 ? ((12.0 - 9.0 * P1 - 6.0 * P2) * x * x * x + (-18.0 + 12.0 * P1 + 6.0 * P2) * x * x + (6.0 - 2.0 * P1)) / 6.0 : ((-P1 - 6.0 * P2) * x * x * x + (6.0 * P1 + 30.0 * P2) * x * x + (-12.0 * P1 - 48.0 * P2) * x + (8.0 * P1 + 24.0 * P2)) / 6.0)
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
    float fcoord = fract(PASS3_pos.x * input_size.x - 0.5);
    vec2 base = PASS3_pos - fcoord * PASS3_pt * vec2(1.0, 0.0);
    float scale = (input_size.x / target_size.x) * AA;
    float r = ceil(R * scale);
    float weight;
    vec4 csum = vec4(0.0);
    float wsum = 0.0;
    for (float i = 1.0 - r; i <= r; ++i) {
        weight = get_weight(abs((i - fcoord) / scale));
        csum += textureLod(PASS3_raw, base + PASS3_pt * vec2(i, 0.0), 0.0) * weight;
        wsum += weight;
    }
    return csum / wsum;
}

//!HOOK MAIN
//!BIND PASS4
//!SAVE PASS5
//!WIDTH OUTPUT.w
//!HEIGHT OUTPUT.h
//!WHEN OUTPUT.w OUTPUT.h * MAIN.w MAIN.h * <
//!DESC alt downscale pass5

////////////////////////////////////////////////////////////////////////
// USER CONFIGURABLE, PASS 5 (blur in y axis)
//
//CAUTION! probably should use the same settings for "USER CONFIGURABLE, PASS 6" below
//
#define SIGMA 1.0 //blur spread or amount, (0.0, 10+]
#define RADIUS 3.0 //kernel radius (integer as float, e.g. 3.0), (0.0, 10+]; probably should set it to ceil(3 * sigma)
//
////////////////////////////////////////////////////////////////////////

#define get_weight(x) (exp(-(x * x / (2.0 * SIGMA * SIGMA))))

vec4 hook() {
    float weight = get_weight(0.0);
    vec4 csum = textureLod(PASS4_raw, PASS4_pos, 0.0) * weight;
    float wsum = weight;
    for(float i = 1.0; i <= RADIUS; ++i) {
        weight = get_weight(i);
        csum += textureLod(PASS4_raw, PASS4_pos + PASS4_pt * vec2(0.0, -i), 0.0) * weight;
        csum += textureLod(PASS4_raw, PASS4_pos + PASS4_pt * vec2(0.0, i), 0.0) * weight;
        wsum += 2.0 * weight;
    }
    return csum / wsum;
}

//!HOOK MAIN
//!BIND PASS4
//!BIND PASS5
//!WIDTH OUTPUT.w
//!HEIGHT OUTPUT.h
//!WHEN OUTPUT.w OUTPUT.h * MAIN.w MAIN.h * <
//!DESC alt downscale pass6

////////////////////////////////////////////////////////////////////////
// USER CONFIGURABLE, PASS 6 (blur in x axis and aply unsharp mask)
//
//CAUTION! probably should use the same settings for "USER CONFIGURABLE, PASS 5" above
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
    float weight = get_weight(0.0);
    vec4 csum = textureLod(PASS5_raw, PASS5_pos, 0.0) * weight;
    float wsum = weight;
    for(float i = 1.0; i <= RADIUS; ++i) {
        weight = get_weight(i);
        csum += textureLod(PASS5_raw, PASS5_pos + PASS5_pt * vec2(-i, 0.0), 0.0) * weight;
        csum += textureLod(PASS5_raw, PASS5_pos + PASS5_pt * vec2(i, 0.0), 0.0) * weight;
        wsum += 2.0 * weight;
    }
    vec4 original = textureLod(PASS4_raw, PASS4_pos, 0.0);
    return delinearize(original + (original - csum / wsum) * AMOUNT);
}
