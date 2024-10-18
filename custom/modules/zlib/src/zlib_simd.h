#ifndef ZLIB_SIMD_H
#define ZLIB_SIMD_H

#if __ARM_FEATURE_CRC32
#define INFLATE_CHUNK_SIMD_NEON
#define INFLATE_CHUNK_READ_64LE
#define ADLER32_SIMD_NEON
#endif

#ifdef __SSE2__
#include <intrin.h>
#define HAS_SSE2
#define INFLATE_CHUNK_SIMD_SSE2
#define INFLATE_CHUNK_READ_64LE
#endif

#ifdef __SSSE3__
#define ADLER32_SIMD_SSSE3
#endif

#ifdef __SSE4_2__
#define HAS_SSE42
#endif

#ifdef __PCLMUL__
#define HAS_PCLMUL
#define SKIP_CPUID_CHECK
#endif

#endif