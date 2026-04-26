# ReSukiSU plus SUSFS for WSA x86_64

Author and maintainer: Ognisty321

This repository provides a Windows Subsystem for Android kernel build with ReSukiSU, SUSFS and x86_64 KPM support.

The base goal is a usable ReSukiSU kernel for WSA 2407 style x86_64 builds. On top of that, this fork adds the missing x86_64 KPM runtime so ReSukiSU Manager can use KPM on WSA instead of only showing the normal root and SUSFS features.

The public ReSukiSU and SukiSU KPM flow was designed around ARM64 KernelPatch payloads. WSA uses an x86_64 Linux kernel, so enabling `CONFIG_KPM=y` was not enough. The ARM64 `kpimg` and `kptools` path could not patch the WSA `bzImage`, could not load x86_64 KPM objects and could not provide an x86_64 inline hook backend. This fork fills that WSA x86_64 gap directly in the kernel tree.

## Current Release

1. Release: `wsa-x86_64-kpm-v0.20`
2. Kernel: `5.15.104-windows-subsystem-for-android-20230927-WSA-ReSukiSU+`
3. Build: `#20`
4. Architecture: `x86_64`
5. KPM version: `ReSukiSU-x86_64-KPM-loader/0.20`
6. Kernel SHA256: `7715bbafba6744ca8f5e091694af60c1e9b38fd08846a85243be691905c4cf8f`

Release download:

```text
https://github.com/Ognisty321/WSA-Linux-Kernel/releases/tag/wsa-x86_64-kpm-v0.20
```

## Project Features

1. WSA 5.15.104 x86_64 kernel base.
2. ReSukiSU integration.
3. SUSFS integration.
4. KPM enabled as a working x86_64 runtime, not only a config flag.
5. Tested release artifact for users who do not want to rebuild the kernel.
6. Public build and install documentation without machine specific paths.

## KPM Port Details

1. Android x86_64 `ksud kpm` command path enabled for ReSukiSU Manager.
2. x86_64 `ET_REL` KPM loader added with `.kpm.info`, `.kpm.init`, `.kpm.exit`, optional `.kpm.ctl0` and optional `.kpm.ctl1`.
3. x86_64 RELA relocation support added for common kernel style KPM objects.
4. KernelPatch style compatibility symbols added for memory helpers, symbol lookup, hotpatch, inline hook, function pointer hook, `hook_wrap` and `fp_hook_wrap`.
5. x86_64 inline hook trampoline backend added with RIP relative instruction relocation.
6. Normal in range inline hook install and restore use the kernel `text_poke_bp()` INT3 patching mechanism.
7. Generated trampoline and wrapper code uses `RW+NX` and `ROX` executable memory transitions.
8. Tasks RCU synchronization is used before generated executable buffers are freed.
9. Unsafe or conflicting hook targets owned by ftrace, kprobes, alternatives, jump labels or static calls are refused.

## Why This Port Exists

WSA is x86_64.

Most existing KPM support in ReSukiSU, SukiSU and KernelPatch related projects assumes ARM64. The ARM64 flow uses ARM64 image parsing, ARM64 branch patching, ARM64 relocation handling and ARM64 cache maintenance. That does not apply to the WSA kernel.

This project does not emulate ARM64 KPM modules. It provides an x86_64 KPM host so x86_64 aware KPM modules can be built and tested for WSA.

## Compatibility

1. ARM64 `.kpm` binaries do not load on this x86_64 kernel.
2. KPMs with source code can be ported when they avoid ARM64 assembly, ARM64 syscall numbers, ARM64 system registers and ARM64 branch helper assumptions.
3. Direct syscall hook wrappers are exported for compatibility, but install calls intentionally return `EOPNOTSUPP` in this release.
4. The tested target is WSA 2407 style `5.15.104` x86_64. Other WSA releases need their own validation.

## Validation

The tested build passed:

1. Basic KPM load, info, control and unload.
2. Hotpatch and function pointer hook capability checks.
3. Inline hook install, trampoline call and restore checks.
4. `hook_wrap` and `fp_hook_wrap` checks.
5. x86_64 instruction relocation checks.
6. Malformed `.kpm.info` rejection.
7. Unsupported syscall hook rejection.
8. `500` loops across `5` capability modules, for `2500` load, control and unload cycles.
9. Final `kpm num = 0`.
10. Kernel log check clean for kernel `BUG`, `WARNING`, `Oops`, general protection faults, invalid opcode reports and use after free reports.

The stock WSA config used here does not enable `KASAN`, `KCSAN`, `DEBUG_WX`, `IBT`, `CFI` or `FineIBT`. Those rows require a separate debug kernel.

## Repository Layout

1. `README_WSA_X86_64_KPM.md` contains the WSA build and install guide.
2. `KernelSU` points to the matching ReSukiSU branch for this port.
3. `KernelSU/docs/WSA_X86_64_KPM.md` documents the ReSukiSU loader side.
4. `KernelSU/kernel/kpm/kpm_loader_x86_64.c` contains the main x86_64 KPM loader implementation.
5. `fs/susfs.c` and `include/linux/susfs*.h` contain the SUSFS integration.

## Build

Clone with submodules:

```bash
git clone --recurse-submodules https://github.com/Ognisty321/WSA-Linux-Kernel.git
cd WSA-Linux-Kernel
git checkout main
git submodule update --init --recursive
```

Build:

```bash
make ARCH=x86_64 LLVM=1 -j"$(nproc)" bzImage
```

The output kernel image is:

```text
arch/x86/boot/bzImage
```

## Install

Use the unpacked WSA directory on your own machine. In the examples below, replace `C:\Path\To\WSA` with your WSA directory.

PowerShell:

```powershell
$WsaDir = "C:\Path\To\WSA"
$KernelImage = "C:\Path\To\WSA-Linux-Kernel\arch\x86\boot\bzImage"

Copy-Item -Force "$WsaDir\Tools\kernel" "$WsaDir\Tools\kernel.backup"
Copy-Item -Force $KernelImage "$WsaDir\Tools\kernel"
Add-AppxPackage -ForceApplicationShutdown -ForceUpdateFromAnyVersion -Register "$WsaDir\AppxManifest.xml"
```

Verify:

```powershell
adb connect 127.0.0.1:58526
adb shell uname -a
```

Expected KPM version:

```text
ReSukiSU-x86_64-KPM-loader/0.20
```

## KPM Build Notes

KPM modules should be built as x86_64 non PIC RELA objects. A working baseline is:

```text
-mcmodel=kernel -mno-red-zone -mno-sse -mno-mmx -mno-avx -fno-jump-tables -fcf-protection=none -mretpoline-external-thunk -fno-pic -fno-plt -fno-common
```

## Branches

1. `main` is the public default branch for this WSA x86_64 ReSukiSU, SUSFS and KPM port.
2. `wsa-x86_64-kpm` is kept as a named development branch for the same port line.
3. The `KernelSU` submodule follows `Ognisty321/ReSukiSU` on the matching branch.

## Credits

This work builds on Microsoft WSA Linux Kernel, ReSukiSU, KernelSU, SukiSU related research, SUSFS and the Linux x86 text patching infrastructure.
