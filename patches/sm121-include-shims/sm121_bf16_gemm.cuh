// GB10 shim: define the sm120 impl under the sm121 symbol (family-compatible).
// The JIT dispatcher derives BOTH the include name and the kernel template
// name from the device arch, so the rename must happen at definition time.
#define sm120_bf16_gemm sm121_bf16_gemm
#include <deep_gemm/impls/sm120_bf16_gemm.cuh>
#undef sm120_bf16_gemm
