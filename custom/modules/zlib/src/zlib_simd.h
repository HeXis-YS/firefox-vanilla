#ifndef ZLIB_SIMD_H
#define ZLIB_SIMD_H

#if defined(__x86_64__)

#define X86_FEATURES

#if defined(__SSE2__)
#define X86_SSE2
#endif

#if defined(__SSSE3__)
#define X86_SSSE3
#endif

#if defined(__SSE4_2__)
#define X86_SSE42
#endif

#if defined(__PCLMUL__)
#define X86_PCLMULQDQ_CRC
#endif

#if defined(__AVX2__)
#define X86_AVX2
#endif

#if defined(__AVX512F__) && defined(__AVX512DQ__) && defined(__AVX512BW__) && defined(__AVX512VL__)
#define X86_AVX512
#endif

#if defined(X86_AVX512) && defined(__AVX512VNNI__)
#define X86_AVX512VNNI
#endif

#if defined(X86_AVX512) && defined(__VPCLMULQDQ__)
#define X86_VPCLMULQDQ_CRC
#endif

#elif defined(__aarch64__)

#define ARM_FEATURES

#if defined(__ARM_NEON) || defined(__ARM_NEON__)
#define ARM_NEON
#define ARM_NEON_HASLD4
#endif

#if defined(__ARM_ACLE) && defined(__ARM_FEATURE_CRC32)
#define ARM_ACLE
#endif

#endif
#endif