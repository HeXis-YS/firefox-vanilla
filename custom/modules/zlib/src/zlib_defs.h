#ifndef ZLIB_DEFS_H
#define ZLIB_DEFS_H

#if defined(__x86_64__)

#define X86_FEATURES

// #ifdef __XSAVE__
// #define X86_HAVE_XSAVE_INTRIN
// #endif

#ifdef __SSE2__
#define X86_SSE2
#endif

#ifdef __SSSE3__
#define X86_SSSE3
#endif

#ifdef __SSE4_2__
#define X86_SSE42
#endif

#ifdef __PCLMUL__
#define X86_PCLMULQDQ_CRC
#endif

#ifdef __AVX2__
#define X86_AVX2
#endif

#ifdef __AVX512F__
#if defined(__AVX512DQ__) && defined(__AVX512BW__) && defined(__AVX512VL__)
#define X86_AVX512
#ifdef __AVX512VNNI__
#define X86_AVX512VNNI
#endif
#endif
#ifdef __VPCLMULQDQ__
#define X86_VPCLMULQDQ_CRC
#endif
#endif

#elif defined(__aarch64__)

#define ARM_FEATURES

#if defined(__ARM_ACLE) && defined(__ARM_FEATURE_CRC32)
#define ARM_ACLE
#endif

#ifdef __ARM_NEON__
#define ARM_NEON
#define ARM_NEON_HASLD4
#endif

#endif
#endif