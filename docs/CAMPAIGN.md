# Campaign log — DSpark GLM-5.2 on 4×GB10 (2026-07-02)

Compressed narrative of the two-path campaign. All timestamps one calendar day;
PRs #46995 (DSpark engine) merged upstream 2026-07-01, #47093 (speculators
checkpoint support) 2026-07-02 ~00:30Z; first serve of GLM-5.2+DSpark on GB10
landed 2026-07-02 ~22:40 local.

## Path A — official nightly (abandoned at wall 6)
Stock `vllm/vllm-openai:nightly-aarch64` (dev714, contains both PRs).
Positive findings: GlmMoeDsa loads on STOCK nightly (the January Marlin-PTX and
DSA gates are fixed upstream); the negative-KV-blocks estimator bug is fixed
upstream (computed +1428–1711 blocks). Walls hit: JSON quoting (1), draft-KV
inherit (2 — patched, kept for good), deep_gemm arch assert (3 — ported the
January sm12x Triton bypass), and the flashinfer 0.6.13 autotuner busy-spin
(5/6 — 96% GPU util at 16W idle power, the definitive spin signature; survived
autotune-off flags because a warmup path bypassed the gate).

## Path B — vllm-dspark024:gb10 (the DSV4F port; abandoned at wall 12)
Rationale: proven deep_gemm + compiled flashinfer sparse-MLA on this silicon.
The transplant itself was clean (17 files, 2 hand-resolved conflicts, import-gated).
Walls: aidendle deep_gemm can't cross into nightly (4); latent flashmla import-order
bug (7); deep_gemm JIT sm121 include/symbol chain (8/9/10 — solved with the
define-rename shim set, REUSABLE for any deep_gemm JIT on GB10); flashinfer
0.6.12/0.6.13 kwarg skew (11 — solved signature-adaptively); and finally the
hardware-shaped dead end (12): 0.24 routes GLM DSA through
FLASHINFER_MLA_SPARSE_SM120, which hardcodes the fp8_ds_mla cache and XQA MLA
accepts only (fp8,fp8) or (bf16,bf16) — a bf16-activation model (QuantTrio)
with fp8 cache is unservable on that path, and the backend ignores
--kv-cache-dtype. DSV4F only ever worked here because its activations are fp8.

## Path C — the January GLM image (SERVED)
`vllm-glm52-cuda130:full` (0.23.1rc @ ab666069 + CUDA-13.0 rebuild + sm12x DSA
mods) — the image that served QuantTrio at 15.3 tok/s for hours. Cherry-picking
both PRs onto ITS exact base commit: one small conflict (sparse_swa.py, superset
resolution), then the 3-way merge vs the live image tree came back **zero
conflicts** (20 files; the GLM mods and DSpark PRs are disjoint). Wall 13:
launching with a foreign launcher (bare bash entrypoint + 0.24-port LD_PRELOAD)
kills PyNccl bootstrap — the image's own `/opt/nvidia/nvidia_entrypoint.sh` and
a clean env are required. Reverting to the proven launcher pair (+DSPARK_DRAFT
env) served on the second try.

## Measured (epoch-1 draft, k=7)
Single 11.3–12.4 tok/s; C2 15.9; accepted length 2.16 over 857 notarized drafts;
per-position 0.60/0.30/0.14/0.06/0.03/0.02. Reference on FP8 target: 3.376 /
pos-1 0.78. Conclusion: quantized-target hidden-state shift halves acceptance;
DSpark-as-shipped lands below the MTP k=3 baseline (15.3) on this target.
Next: QuantTrio-native draft retrain (speculators online recipe), k=3–4, epoch-2/3.

## Meta-lesson
The mid-campaign switch from launch-iterate ("whack-a-mole") to static-first
analysis (pyflakes, import gates, signature diffs vs installed libraries,
call-site vs kernel-def audits) found walls 7, 8-pre, 11 and 12 BEFORE paying
a 12-minute launch for each. On frontier ports, run the static sweep first.
