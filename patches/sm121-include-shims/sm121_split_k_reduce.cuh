// GB10 shim: define the sm120 impl under the sm121 symbol (family-compatible).
// The JIT dispatcher derives BOTH the include name and the kernel template
// name from the device arch, so the rename must happen at definition time.
#define sm120_split_k_reduce sm121_split_k_reduce
#include <deep_gemm/impls/sm120_split_k_reduce.cuh>
#undef sm120_split_k_reduce
