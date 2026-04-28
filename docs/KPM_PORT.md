# x86_64 KPM Port for WSA

This document describes what the WSA x86_64 KPM port does, how it diverges from the ARM64 KernelPatch flow used by mainline ReSukiSU and SukiSU, and what is intentionally not implemented.

## Why a Port Was Needed

The public KPM ecosystem grew on top of KernelPatch, which is built around AArch64 specifics:

1. ARM64 fixed length 4 byte instructions.
2. ARM64 branch helper macros and inline hook trampoline encoding.
3. ARM64 system register access patterns (`mrs sp_el0`, `tcr_el1`).
4. AArch64 ELF and `R_AARCH64_*` relocations.
5. ARM64 syscall numbers and `compat_sys_call_table` semantics.
6. ARM64 boot image / `Image` parsing in `kptools`.

WSA runs an x86_64 Linux kernel, so a normal ReSukiSU build with `CONFIG_KPM=y` exposes the API surface but does not provide a real x86_64 backend behind it.

## Scope of This Port

Implemented:

1. Android x86_64 `ksud kpm` command path enabled for ReSukiSU Manager.
2. x86_64 `ET_REL` KPM ELF loader with bounds checks on header, sections, strings, relocations and entry points.
3. x86_64 RELA relocation handling for the relocation types kernel style modules need: `R_X86_64_64`, `R_X86_64_PC32`, `R_X86_64_PLT32`, `R_X86_64_32`, `R_X86_64_32S`, `R_X86_64_GOTPCREL`, `R_X86_64_GOTPCRELX`, `R_X86_64_REX_GOTPCRELX`.
4. KernelPatch style compatibility symbols: `kpver`, `kver`, `kp_malloc`, `kp_free`, `compat_copy_to_user`, `symbol_lookup_name`, `hotpatch`, `hook`, `hook_wrap`, `fp_hook`, `fp_hook_wrap`.
5. x86_64 inline hook backend that uses the kernel `insn` decoder for length and RIP relative fixup.
6. `text_poke_bp()` based install and restore for normal `JMP rel32` hooks under `text_mutex`.
7. `RW+NX` to `ROX` page transitions for trampolines and wrapper stubs.
8. `synchronize_rcu_tasks_rude()` plus `synchronize_rcu_tasks()` before generated executable buffers are freed.
9. Refusal of unsafe or conflicting hook targets owned by ftrace, kprobes, alternatives, jump labels or static calls.
10. Refusal of patching from IRQ or atomic context.
11. Native x86_64 syscall-table wrappers through `hook_syscalln`, `fp_wrap_syscalln` and `inline_wrap_syscalln`.

Intentionally not implemented in this release:

1. Compat syscall-table wrapping; compat syscall install calls return `EOPNOTSUPP`.
2. ARM64 branch helper APIs (`branch_from_to`, `branch_relative`, `branch_absolute`, `ret_absolute`).
3. ARM64 `kpimg` style boot time patching of the kernel image.

## Loader ABI

The formal x86_64 ABI contract is in [`KernelSU/docs/KPM_X86_64_ABI.md`](../KernelSU/docs/KPM_X86_64_ABI.md). The current loader marker is `ReSukiSU-x86_64-KPM-loader/0.21` with ABI version `1`.

Patch hygiene and rebase rules are in [`KernelSU/docs/UPSTREAMING_X86_64.md`](../KernelSU/docs/UPSTREAMING_X86_64.md).

KPM modules are x86_64 `ET_REL` ELF objects that expose these sections:

1. `.kpm.info` text metadata: name, version, license, author, description.
2. `.kpm.init` initialization entry (`KPM_INIT`).
3. `.kpm.exit` cleanup entry (`KPM_EXIT`).
4. `.kpm.ctl0` optional first control entry (`KPM_CTL0`).
5. `.kpm.ctl1` optional second control entry (`KPM_CTL1`).

Lifecycle:

```text
load -> kpm_init(args, "load", reserved)
ctl  -> kpm_ctl0(ctl_args, out_msg, outlen)
ctl  -> kpm_ctl1(a1, a2, a3)
unload -> kpm_exit(reserved)
```

The loader exports `kpm_loader_abi_version`, `kpm_abi_version`, `kpm_loader_feature_bits` and `kpm_feature_bits` so modules can detect optional x86_64 runtime capabilities.

The source-level porting checklist is in [`KernelSU/docs/KPM_X86_64_PORTING.md`](../KernelSU/docs/KPM_X86_64_PORTING.md). WSA module compatibility rows and evidence requirements are tracked in [`KPM_MODULE_COMPATIBILITY.md`](KPM_MODULE_COMPATIBILITY.md).

## Hook Backend

Normal in range inline hook:

1. The patcher acquires `text_mutex`.
2. `text_poke_bp()` installs a 5 byte `JMP rel32` to a per hook trampoline. The breakpoint emulation step uses the new jump itself.
3. The trampoline contains the relocated original prologue, copied with the kernel `insn` decoder, with RIP relative operands rewritten and overflowing displacements rejected with `-ERANGE`.
4. The trampoline pages start `RW+NX`, are populated, then transition to `ROX`.

Restore:

1. The patcher acquires `text_mutex`.
2. `text_poke_bp()` writes the original prologue bytes back. The breakpoint emulation step uses the previous jump bytes so that any in flight CPU continues into the trampoline rather than into a half restored prologue.
3. `synchronize_rcu_tasks_rude()` and `synchronize_rcu_tasks()` are called before the trampoline pages are freed, so no task can still be running inside them.

Far jump fallback:

1. If the trampoline cannot be reached from the hooked function with a 5 byte `JMP rel32`, the install path falls back to a 14 byte absolute jump emitted by the existing ReSukiSU x86_64 text writer.

Refusal predicates at install time include:

1. The address must lie inside core kernel text.
2. `ftrace_location()` and `is_ftrace_trampoline()` must be clean.
3. `get_kprobe()` must return null.
4. The address must not lie inside `.entry.text`, `.noinstr.text`, exception tables, alternatives, jump labels or static call tables.

## Safety Semantics

1. `hotpatch(addrs, values, cnt)` snapshots all original 32 bit values before commit and rolls back earlier writes if a later write fails.
2. `unload` marks a module as unloading before calling `.kpm.exit`; `control` returns `-EBUSY` while this is in progress.
3. If `.kpm.exit` returns an error, the module remains loaded rather than freeing executable memory that hooks or callbacks may still reference.
4. `ksud kpm` propagates negative kernel return codes as command failures instead of reporting success.
5. `ksud kpm doctor --json` reports loader reachability, module count, safe mode and KPM directory hardening.

## Manager Packaging

ReSukiSU Manager must ship an Android x86_64 `libksud.so` with the `ksud kpm` command path. The local guard checks an APK or extracted library:

```bash
KernelSU/scripts/check-manager-kpm-x86.sh /path/to/ReSukiSU-Manager.apk
```

The release checklist should record the Manager APK version, APK SHA256, guard output, `ksud kpm version`, `ksud kpm doctor --json` and `ksud kpm audit --json`. See [`KernelSU/docs/MANAGER_X86_64.md`](../KernelSU/docs/MANAGER_X86_64.md).

## KPM Build Flags

For out of tree x86_64 KPM modules:

```text
-mcmodel=kernel -mno-red-zone -mno-sse -mno-mmx -mno-avx -fno-jump-tables -fcf-protection=none -mretpoline-external-thunk -fno-pic -fno-plt -fno-common
```

Rationale:

1. `-mcmodel=kernel` keeps the kernel `[-2 GB, 0)` code model.
2. `-mno-red-zone`, `-mno-sse`, `-mno-mmx`, `-mno-avx` match the kernel ABI.
3. `-fno-jump-tables` keeps prologues hookable.
4. `-fcf-protection=none` avoids generating `endbr64` from user toolchain in places the loader does not expect.
5. `-mretpoline-external-thunk` routes indirect calls through the kernel retpoline thunks.
6. `-fno-pic -fno-plt -fno-common` keep the object file structure that the loader expects.

## Validation Done

The x86_64 validation suite covers:

1. Basic KPM ABI (`load`, `info`, `control`, `unload`).
2. Hotpatch and function pointer hook capability checks.
3. Inline hook install, trampoline call and restore checks.
4. `hook_wrap` and `fp_hook_wrap` checks for argument counts up to 12.
5. x86_64 instruction relocation cases including RIP relative MOV / LEA, ENDBR64, 10 byte `movabs`, refusal of `call rel32` and short branches in the prologue.
6. Malformed `.kpm.info` rejection.
7. Native syscall wrapper load/unload and compat syscall rejection.
8. Hook ownership tagging from a `.kpm.ctl0` callback.
9. `500` loops across `5` capability modules, for `2500` total load / control / unload cycles.
10. Final `kpm num = 0`.
11. Kernel log clean for `BUG`, `WARNING`, `Oops`, general protection faults, invalid opcode reports and use after free reports.

The current local known-good row is WSA package `2407.40000.4.0` on Windows build `26200` with Memory Integrity enabled. Kernel `#36` (`f6c7694e5d1c04f063ba6229ddf190634664c62b1fe6c62fbe6c6ec625819af1`) passed with loader `ReSukiSU-x86_64-KPM-loader/0.21`:

```bash
cd KernelSU
RUN_WSA=1 ADB="/mnt/d/Programy/Path Tools/adb.exe" ADB_TARGET=127.0.0.1:58526 \
  KSUD=/data/local/tmp/ksud.kpm-capable REMOTE_DIR=/data/local/tmp/kpm-test CONTROL_LOOPS=20 \
  bash scripts/kpm-x86-preflight.sh
cd ..
ADB="/mnt/d/Programy/Path Tools/adb.exe" ADB_TARGET=127.0.0.1:58526 \
  bash scripts/wsa-kpm-boot-smoke.sh
```

## Open Validation

The stock WSA configuration does not enable `KASAN`, `KCSAN`, `DEBUG_WX`, `IBT`, `CFI` or `FineIBT`. The detailed matrix, exact commands and result template live in [KPM_DEBUG_VALIDATION.md](KPM_DEBUG_VALIDATION.md). Validation rows that need these configs are tracked here for future debug kernel runs:

1. CFI / IBT / FineIBT compliance (Clang LTO + `CONFIG_CFI_CLANG=y` + `CONFIG_X86_KERNEL_IBT=y` + `CONFIG_FINEIBT=y`).
2. `endbr64` preservation under IBT (hook at `func+4`).
3. `text_poke_bp` atomicity under multi CPU stress with concurrent `perf record -a -F 8000`.
4. `KASAN_VMALLOC`, `KCSAN`, `KFENCE`, `DEBUG_WX`, `PROVE_LOCKING`, `DEBUG_LIST`, `DEBUG_KMEMLEAK` 24 hour stress soak.
5. Longer AFL++ / libFuzzer runs beyond the smoke harness and generated example/mutation seed corpus.
6. ftrace / kprobes / livepatch coexistence.

## Compatibility

1. ARM64 `.kpm` binaries cannot load on this x86_64 kernel.
2. Source level KPMs port cleanly when they avoid ARM64 inline asm, ARM64 syscall numbers, ARM64 system registers and ARM64 branch helpers. Use [`KernelSU/docs/KPM_X86_64_PORTING.md`](../KernelSU/docs/KPM_X86_64_PORTING.md) and `KernelSU/scripts/check-kpm-module-x86.sh` before claiming compatibility for a real module.
3. WSA does not have most vendor specific Android drivers, so KPMs that target a specific phone vendor (`qti_battery_charger`, `xperia_ii_battery_age`, vendor freezers) cannot work on WSA regardless of architecture.
