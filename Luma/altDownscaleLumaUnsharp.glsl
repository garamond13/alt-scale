//!HOOK LUMA
//!BIND HOOKED
//!SAVE PASS1
//!WHEN OUTPUT.w OUTPUT.h * LUMA.w LUMA.h * <
//!DESC alt downscale luma pass1

vec4 hook()
{
	return linearize(HOOKED_tex(HOOKED_pos));
}

//!HOOK LUMA
//!BIND PASS1
//!SAVE PASS2
//!HEIGHT OUTPUT.h
//!WHEN OUTPUT.w OUTPUT.h * LUMA.w LUMA.h * <
//!DESC alt downscale luma pass2

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
// USER CONFIGURABLE, PASS 2 (downsample in y axis)
//
// CAUTION! should use the same settings for "USER CONFIGURABLE, PASS 3" below
//
#define K LANCZOS // kernel function, see "KERNEL FUNCTIONS LIST"
#define R 2.0 // kernel radius, (0.0, inf)
#define B 1.0 // kernel blur, (0.0, inf)
//
// kernel function parameters
#define P1 0.0 // COSINE: n, GARAMOND: n, BLACKMAN: a, GNW: s, SAID: chi, FSR: b, BCSPLINE: B
#define P2 0.0 // GARAMOND: m, BLACKMAN: n, GNW: n, SAID: eta, FSR: c, BCSPLINE: C
//
////////////////////////////////////////////////////////////////////////

#define M_PI 3.14159265358979323846
#define M_PI_2 1.57079632679489661923
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

vec4 hook()
{
	float f = fract(PASS1_pos.y * PASS1_size.y - 0.5);
	vec2 base = vec2(PASS1_pos.x, PASS1_pos.y - f * PASS1_pt.y);
	float weight;
	float csum = 0.0;
	float wsum = 0.0;
	float scale = PASS1_size.y / target_size.y;
	for (float i = 1.0 - ceil(R * scale); i <= ceil(R * scale); ++i) {
		weight = get_weight(abs((i - f) / scale));
		csum += PASS1_tex(vec2(base.x, base.y + i * PASS1_pt.y)).x * weight;
		wsum += weight;
	}
	return vec4(csum / wsum, 0.0, 0.0, 0.0);
}

//!HOOK LUMA
//!BIND PASS2
//!SAVE PASS3
//!WIDTH OUTPUT.w
//!HEIGHT OUTPUT.h
//!WHEN OUTPUT.w OUTPUT.h * LUMA.w LUMA.h * <
//!DESC alt downscale luma pass3

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
// USER CONFIGURABLE, PASS 3 (downsample in x axis)
//
// CAUTION! should use the same settings for "USER CONFIGURABLE, PASS 2" above
//
#define K LANCZOS // kernel function, see "KERNEL FUNCTIONS LIST"
#define R 2.0 // kernel radius, (0.0, inf)
#define B 1.0 // kernel blur, (0.0, inf)
//
// kernel function parameters
#define P1 0.0 // COSINE: n, GARAMOND: n, BLACKMAN: a, GNW: s, SAID: chi, FSR: b, BCSPLINE: B
#define P2 0.0 // GARAMOND: m, BLACKMAN: n, GNW: n, SAID: eta, FSR: c, BCSPLINE: C
//
////////////////////////////////////////////////////////////////////////

#define M_PI 3.14159265358979323846
#define M_PI_2 1.57079632679489661923
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

vec4 hook()
{
	float f = fract(PASS2_pos.x * PASS2_size.x - 0.5);
	vec2 base = vec2(PASS2_pos.x - f * PASS2_pt.x, PASS2_pos.y);
	float weight;
	float csum = 0.0;
	float wsum = 0.0;
	float scale = PASS2_size.x / target_size.x;
	for (float i = 1.0 - ceil(R * scale); i <= ceil(R * scale); ++i) {
		weight = get_weight(abs((i - f) / scale));
		csum += PASS2_tex(vec2(base.x + i * PASS2_pt.x, base.y)).x * weight;
		wsum += weight;
	}
	return vec4(csum / wsum, 0.0, 0.0, 0.0);
}

//!HOOK LUMA
//!BIND PASS3
//!SAVE PASS4
//!WIDTH OUTPUT.w
//!HEIGHT OUTPUT.h
//!WHEN OUTPUT.w OUTPUT.h * LUMA.w LUMA.h * <
//!DESC alt downscale luma pass4

////////////////////////////////////////////////////////////////////////
// USER CONFIGURABLE, PASS 4 (blur in y axis)
//
// CAUTION! should use the same settings for "USER CONFIGURABLE, PASS 5" below
//
#define S 1.0 // blur spread or amount, (0.0, inf)
#define R 2.0 // kernel radius, (0.0, inf)
//
////////////////////////////////////////////////////////////////////////

#define get_weight(x) (exp(-(x) * (x) / (2.0 * S * S)))

vec4 hook()
{
	float weight;
	float csum = PASS3_tex(PASS3_pos).x;
	float wsum = 1.0;
	for (float i = 1.0; i <= R; ++i) {
		weight = get_weight(i);
		csum += (PASS3_tex(PASS3_pos + vec2(0.0, -i) * PASS3_pt).x + PASS3_tex(PASS3_pos + vec2(0.0, i) * PASS3_pt).x) * weight;
		wsum += 2.0 * weight;
	}
	return vec4(csum / wsum, 0.0, 0.0, 0.0);
}

//!HOOK LUMA
//!BIND PASS3
//!BIND PASS4
//!WIDTH OUTPUT.w
//!HEIGHT OUTPUT.h
//!WHEN OUTPUT.w OUTPUT.h * LUMA.w LUMA.h * <
//!DESC alt downscale luma pass5

////////////////////////////////////////////////////////////////////////
// USER CONFIGURABLE, PASS 5 (blur in x axis and apply unsharp mask)
//
// CAUTION! should use the same settings for "USER CONFIGURABLE, PASS 3" above
//
#define S 1.0 // blur spread or amount, (0.0, inf)
#define R 2.0 // kernel radius, (0.0, inf)
//
// sharpnes
#define A 0.5 // amount of sharpening [0.0, inf)
//
////////////////////////////////////////////////////////////////////////

#define get_weight(x) (exp(-(x) * (x) / (2.0 * S * S)))

vec4 hook()
{
	float weight;
	float csum = PASS4_tex(PASS4_pos).x;
	float wsum = 1.0;
	for (float i = 1.0; i <= R; ++i) {
		weight = get_weight(i);
		csum += (PASS4_tex(PASS4_pos + vec2(-i, 0.0) * PASS4_pt).x + PASS4_tex(PASS4_pos + vec2(i, 0.0) * PASS4_pt).x) * weight;
		wsum += 2.0 * weight;
	}
	float original = PASS3_tex(PASS3_pos).x;
	return delinearize(vec4(original + (original - csum / wsum) * A, 0.0, 0.0, 0.0));
}
