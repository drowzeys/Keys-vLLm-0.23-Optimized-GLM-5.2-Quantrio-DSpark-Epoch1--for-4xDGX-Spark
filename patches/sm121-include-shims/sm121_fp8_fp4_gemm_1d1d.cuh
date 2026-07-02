// GB10 shim: define the sm120 impl under the sm121 symbol (family-compatible).
// The JIT dispatcher derives BOTH the include name and the kernel template
// name from the device arch, so the rename must happen at definition time.
#define sm120_fp8_fp4_gemm_1d1d sm121_fp8_fp4_gemm_1d1d
#include <deep_gemm/impls/sm120_fp8_fp4_gemm_1d1d.cuh>
#undef sm120_fp8_fp4_gemm_1d1d
