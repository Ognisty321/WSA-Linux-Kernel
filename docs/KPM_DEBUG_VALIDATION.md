# KPM Debug Validation Matrix

This matrix tracks validation that needs debug or sanitizer kernel builds. The stock WSA release kernel is still the user-facing target, but these rows are the evidence path for loader safety, hook ownership, W^X and race behavior.

## Local Commands

Run fragment checks from a clean source tree. The checker refuses to run when `.config`, `include/config` or generated x86 headers already exist in-tree.

```bash
scripts/wsa-validate-config-fragment.sh configs/wsa/fragments/wsa-x86_64-debug.config
scripts/wsa-validate-config-fragment.sh configs/wsa/fragments/wsa-x86_64-sanitize.config
scripts/wsa-validate-config-fragment.sh configs/wsa/fragments/wsa-x86_64-ibt.config
```

Build a debug artifact and manifest:

```bash
BUILD=1 scripts/wsa-validate-config-fragment.sh configs/wsa/fragments/wsa-x86_64-debug.config
```

When the KernelSU submodule points at a local-only ReSukiSU commit, initialize the validation worktree submodule from the local checkout instead of GitHub:

```bash
git submodule set-url KernelSU /home/ognisty321/Projekty/ReSukiSU
git -c protocol.file.allow=always submodule update --init --force KernelSU
```

Run live KPM validation against a booted WSA instance:

```bash
cd KernelSU
RUN_WSA=1 ADB="/mnt/d/Programy/Path Tools/adb.exe" ADB_TARGET=127.0.0.1:58526 \
  bash scripts/kpm-x86-preflight.sh
```

Then run the boot smoke from the WSA tree:

```bash
ADB="/mnt/d/Programy/Path Tools/adb.exe" ADB_TARGET=127.0.0.1:58526 \
  bash scripts/wsa-kpm-boot-smoke.sh
```

## Matrix

| Area | Kernel config or tool | Required evidence | Current local status |
| --- | --- | --- | --- |
| W^X and generated executable memory | `wsa-x86_64-debug.config`, `DEBUG_WX`, dmesg scan | No `DEBUG_WX`, `W+X`, `writable executable` markers after load/control/unload and hook restore. | Fragment probe available, debug boot pending. |
| Locking and sleep correctness | `PROVE_LOCKING`, `LOCKDEP`, `DEBUG_ATOMIC_SLEEP` | No lockdep or atomic sleep reports during parallel load/control/unload. | Fragment probe available, debug boot pending. |
| List and RCU lifetime | `DEBUG_LIST`, `DEBUG_OBJECTS_RCU_HEAD`, RCU trace | No list corruption or RCU object warnings when unloading hook owners. | Fragment probe available, debug boot pending. |
| Memory lifetime | `KFENCE`, `DEBUG_KMEMLEAK`, optional `KASAN_VMALLOC` | No UAF, leak or invalid access reports after repeated hook install/restore. | Fragment probe available, sanitizer boot pending. |
| Race detection | `KCSAN` where supported | No KCSAN reports under concurrent `control` and unload race. | `KCSAN` is dependency-gated on the 5.15.104 WSA base. |
| Instruction patching | stock plus debug build, `text_poke_bp` path | Inline hook install, trampoline call and restore pass with clean dmesg. | Stock/local preflight builds pass, live debug run pending. |
| Owner context | `control_owner.kpm` sample | Unload is refused while a hook installed from `.kpm.ctl0` is still owned, then succeeds after cleanup. | Stock kernel `#36` live self-test passed; debug-kernel repeat pending. |
| ftrace/kprobe/static text coexistence | debug kernel plus negative KPM cases | Reserved targets return guarded hook errors, not partial patching. | Guard code present, expanded negative runtime matrix pending. |
| IBT/CFI/FineIBT | `wsa-x86_64-ibt.config` or newer validation kernel | `endbr64` behavior is documented and hook refusal is deterministic. | 5.15.104 base drops key IBT/CFI symbols, newer validation kernel needed. |
| ELF parser fuzzing | `scripts/fuzz-kpm-x86-smoke.sh`, libFuzzer when available | Static malformed seeds, built examples and deterministic ELF header mutations pass under sanitizer or standalone harness. | Standalone smoke passes locally, long libFuzzer run pending. |

## Latest Local Fragment Probe

Clean worktree probe on 2026-04-27, WSA source `b47ee5a82`, ReSukiSU submodule `df6fa3e1`, no in-tree generated config artifacts:

| Fragment | Kept | Dropped |
| --- | ---: | --- |
| `wsa-x86_64-debug.config` | 22 | `CONFIG_FRAME_POINTER` |
| `wsa-x86_64-sanitize.config` | 9 | `CONFIG_KCSAN`, `CONFIG_KCSAN_REPORT_RACE_UNKNOWN_ORIGIN`, `CONFIG_KCSAN_VERBOSE`, `CONFIG_UBSAN_LOCAL_BOUNDS` |
| `wsa-x86_64-ibt.config` | 2 | `CONFIG_CFI_CLANG`, `CONFIG_CFI_CLANG_SHADOW`, `CONFIG_CFI_PERMISSIVE`, `CONFIG_FINEIBT`, `CONFIG_X86_KERNEL_IBT` |

The dropped symbols are dependency-gated by the 5.15.104 WSA base, so the stock build remains the target while these fragments define what is available for debug boot validation.

## Result Template

Append a result row or release note with:

1. WSA package full name and Windows build.
2. HVCI state.
3. Kernel commit, ReSukiSU submodule commit and kernel SHA256.
4. Fragment name, kept symbols and dropped symbols.
5. `BUILD_INFO.txt` and `SHA256SUMS.txt` for debug artifacts.
6. `ksud kpm doctor --json` and `ksud kpm audit --json`.
7. Fresh dmesg slice start and end, plus failure scan result.
8. Final `ksud kpm num` result.
