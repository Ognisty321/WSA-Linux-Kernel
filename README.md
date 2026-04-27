# ReSukiSU + SUSFS for WSA x86_64

> Windows Subsystem for Android kernel build with **ReSukiSU**, **SUSFS** and a working **x86_64 KPM runtime**.

[![Build kernel](https://github.com/Ognisty321/WSA-Linux-Kernel/actions/workflows/build.yml/badge.svg?branch=main)](https://github.com/Ognisty321/WSA-Linux-Kernel/actions/workflows/build.yml)
[![Latest release](https://img.shields.io/github/v/release/Ognisty321/WSA-Linux-Kernel?label=release&color=blue)](https://github.com/Ognisty321/WSA-Linux-Kernel/releases/latest)
[![Kernel](https://img.shields.io/badge/kernel-5.15.104-informational)](#current-release)
[![Architecture](https://img.shields.io/badge/arch-x86__64-success)](#current-release)
[![License](https://img.shields.io/badge/license-GPL--2.0-lightgrey)](COPYING)

WSA runs an x86_64 Linux kernel. The public ReSukiSU and SukiSU KPM flow was designed around ARM64 KernelPatch payloads, so flipping `CONFIG_KPM=y` on a WSA build does not give you a working KPM runtime by itself. This fork adds the missing x86_64 side directly inside the kernel tree: an x86_64 KPM ELF loader, x86_64 RELA relocation handling, an inline hook backend with `text_poke_bp()` based install and restore, executable memory hardening and Tasks RCU lifetime for trampolines.

The result is a single WSA kernel where ReSukiSU root, SUSFS hide and KPM modules can all be used on x86_64.

## Current Release

| Field | Value |
| --- | --- |
| Tag | [`wsa-x86_64-kpm-v0.21`](https://github.com/Ognisty321/WSA-Linux-Kernel/releases/tag/wsa-x86_64-kpm-v0.21) |
| Kernel | `5.15.104-windows-subsystem-for-android-20230927-WSA-ReSukiSU+` |
| Build number | `#30` |
| Architecture | `x86_64` |
| KPM loader | `ReSukiSU-x86_64-KPM-loader/0.20` |
| x86_64 KPM ABI | `1` |
| Kernel SHA256 | `037b9507707bffca33c56cc421b5ff7085f8ec8b8f3d2abedb93072bdadfae46` |
| Kernel commit | `84a389e01` |
| ReSukiSU submodule | `a0d26e23` |
| Validated WSA package | `2407.40000.4.0` |
| Validated Windows build | `26200`, Memory Integrity on |

`ReSukiSU-x86_64-KPM-loader/0.20` is the loader runtime/ABI marker. It is intentionally separate from the WSA kernel release tag.

## Quick Start

1. Download the kernel binary from the [latest release](https://github.com/Ognisty321/WSA-Linux-Kernel/releases/latest).
2. Verify SHA256 against the value above.
3. Replace `Tools\kernel` inside your unpacked WSA package and re-register the WSA appx.
4. Boot WSA and run `adb shell uname -a`. The kernel string must contain `WSA-ReSukiSU+`.
5. Open ReSukiSU Manager and confirm `KPM Version: Supported (ReSukiSU-x86_64-KPM-loader/0.20)`.
6. For deeper diagnostics, run `adb shell su -c "ksud kpm doctor --json"`.

Detailed step by step install for Windows is in [docs/INSTALL.md](docs/INSTALL.md).

## Important: HVCI / Memory Integrity

WSA on Windows can run with Hyper-V Memory Integrity (HVCI) on, and current testing shows the WSA Linux guest is not subject to host HVCI W^X enforcement, so KPM inline hooks work. If a future Windows build extends hypervisor enforced W^X to child partitions, the loader is built to detect failed text writes and refuse to install hooks rather than silently break.

If something does not work on your machine, the first thing to try is disabling Memory Integrity on the Windows host and rebooting. Steps for that are in [docs/FAQ.md](docs/FAQ.md).

## What Is Inside

1. WSA 5.15.104 x86_64 kernel base.
2. ReSukiSU integration with `CONFIG_KSU=y` and SUSFS support.
3. SUSFS integration with `CONFIG_KSU_SUSFS=y`.
4. x86_64 KPM runtime, not just `CONFIG_KPM=y`.
5. Tested release artifact for users who do not want to rebuild the kernel.

The KPM port adds:

1. Android x86_64 `ksud kpm` command path enabled for ReSukiSU Manager.
2. x86_64 `ET_REL` KPM loader with `.kpm.info`, `.kpm.init`, `.kpm.exit`, `.kpm.ctl0` and `.kpm.ctl1`.
3. x86_64 RELA relocation support for the relocation types kernel style KPM objects need.
4. KernelPatch style compatibility surface: `kpver`, `kver`, `kp_malloc`, `kp_free`, `compat_copy_to_user`, `symbol_lookup_name`, `hotpatch`, `hook`, `hook_wrap`, `fp_hook`, `fp_hook_wrap`.
5. x86_64 inline hook trampoline backend with kernel `insn` decoder for RIP relative fixup.
6. `text_poke_bp()` based install and restore for normal `JMP rel32` hooks under `text_mutex`.
7. `RW+NX` to `ROX` page transitions for generated code.
8. `synchronize_rcu_tasks_rude()` plus `synchronize_rcu_tasks()` before generated executable buffers are freed.
9. Refusal of unsafe or conflicting hook targets owned by ftrace, kprobes, alternatives, jump labels or static calls.

Full technical write up of the port is in [docs/KPM_PORT.md](docs/KPM_PORT.md). Manager packaging checks live in [KernelSU/docs/MANAGER_X86_64.md](KernelSU/docs/MANAGER_X86_64.md), the source-level module porting checklist is in [KernelSU/docs/KPM_X86_64_PORTING.md](KernelSU/docs/KPM_X86_64_PORTING.md), and WSA module rows are tracked in [docs/KPM_MODULE_COMPATIBILITY.md](docs/KPM_MODULE_COMPATIBILITY.md).

## Compatibility

1. WSA 2407 style `5.15.104` x86_64 is the tested target.
2. ARM64 `.kpm` binaries cannot load on this kernel.
3. KPMs with C source can be ported to x86_64 if they avoid ARM64 assembly, ARM64 syscall numbers, ARM64 system registers and ARM64 branch helpers. Recommended build flags are in [docs/KPM_PORT.md](docs/KPM_PORT.md#kpm-build-flags), with the longer checklist in [KernelSU/docs/KPM_X86_64_PORTING.md](KernelSU/docs/KPM_X86_64_PORTING.md).
4. Direct syscall hook install is intentionally not exposed in this release. The wrapper symbols are present for compatibility, but install calls return `EOPNOTSUPP`.

## Validation

The release build was stress tested with capability KPMs covering basic KPM ABI, hotpatch, function pointer hook, inline hook, trampoline restore, `hook_wrap`, `fp_hook_wrap`, x86_64 instruction relocation cases, malformed metadata rejection and unsupported syscall hook rejection.

```text
500 loops x 5 modules = 2500 load/control/unload cycles
final kpm num = 0
kernel log clean for BUG / WARNING / Oops / GP fault / invalid opcode / use after free
```

The stock WSA configuration does not enable `KASAN`, `KCSAN`, `DEBUG_WX`, `IBT`, `CFI` or `FineIBT`. Validation rows that require those configs need a separate debug kernel build and are tracked in [docs/KPM_PORT.md](docs/KPM_PORT.md#open-validation).

## Repository Layout

| Path | Purpose |
| --- | --- |
| [docs/INSTALL.md](docs/INSTALL.md) | Step by step Windows install for users. |
| [docs/BUILD.md](docs/BUILD.md) | Reproducible build instructions for WSL2 / Linux. |
| [docs/KPM_PORT.md](docs/KPM_PORT.md) | Technical description of the x86_64 KPM port. |
| [docs/KPM_DEBUG_VALIDATION.md](docs/KPM_DEBUG_VALIDATION.md) | Debug kernel validation matrix for W^X, races, owner context and fuzzing. |
| [docs/KPM_MODULE_COMPATIBILITY.md](docs/KPM_MODULE_COMPATIBILITY.md) | WSA x86_64 KPM module compatibility tracker and evidence gate. |
| [docs/FAQ.md](docs/FAQ.md) | Common questions and recovery steps. |
| [CHANGELOG.md](CHANGELOG.md) | Release history. |
| `KernelSU/` | Submodule pointing at the matching [`Ognisty321/ReSukiSU`](https://github.com/Ognisty321/ReSukiSU) branch. |
| `KernelSU/docs/KPM_X86_64_ABI.md` | Formal x86_64 KPM ABI contract. |
| `KernelSU/docs/KPM_X86_64_PORTING.md` | Source-level ARM64 KPM to WSA x86_64 porting checklist. |
| `KernelSU/docs/MANAGER_X86_64.md` | ReSukiSU Manager and `libksud.so` x86_64 packaging checklist. |
| `KernelSU/docs/UPSTREAMING_X86_64.md` | Patch hygiene and rebase checklist for the x86_64 KPM port. |
| `KernelSU/scripts/check-kpm-module-x86.sh` | Local `.kpm` artifact checker for x86_64 WSA compatibility rows. |
| `KernelSU/scripts/check-manager-kpm-x86.sh` | Local APK or `libksud.so` packaging guard. |
| `KernelSU/kernel/kpm/kpm_loader_x86_64.c` | Main x86_64 KPM loader. |
| `KernelSU/kernel/hook/x86_64/patch_memory.c` | x86_64 text patching backend. |
| `fs/susfs.c`, `include/linux/susfs*.h` | SUSFS integration. |

## Branches

1. `main` is the public default branch for this WSA x86_64 ReSukiSU + SUSFS + KPM port.
2. The `KernelSU` submodule follows `Ognisty321/ReSukiSU` on the matching branch.

## Reporting Issues

If something is broken, please open an issue in the [issue tracker](https://github.com/Ognisty321/WSA-Linux-Kernel/issues) using one of the templates. Include `adb shell uname -a`, `adb shell su -c "ksud kpm version"`, `adb shell su -c "ksud kpm doctor --json"` and the relevant `dmesg` slice.

## Credits

This work builds on the Microsoft WSA Linux Kernel, KernelSU by tiann, ReSukiSU, SukiSU related research, SUSFS by simonpunk and the Linux x86 text patching infrastructure. The x86_64 KPM port and packaging in this repository is by Ognisty321.

## License

The kernel itself is GPL-2.0. KernelSU components retain their upstream licenses. See [COPYING](COPYING), [LICENSES/](LICENSES) and [KernelSU/LICENSE](https://github.com/Ognisty321/ReSukiSU/blob/main/LICENSE).
