# WSA x86_64 ReSukiSU Build Guide

Author and maintainer: Ognisty321

This guide explains how to build and install the ReSukiSU plus SUSFS plus KPM kernel for WSA x86_64.

## Overview

The original WSA kernel is x86_64. This fork ports ReSukiSU and SUSFS onto that base and also adds x86_64 KPM support.

The KPM part needed extra work because the public KPM patching flow used by ReSukiSU and SukiSU is centered on ARM64 KernelPatch payloads. A normal WSA ReSukiSU build can enable `CONFIG_KPM=y`, but it still does not provide a real x86_64 KPM runtime. This fork adds that missing runtime directly in the ReSukiSU kernel integration.

## Tested Release

1. Release: `wsa-x86_64-kpm-v0.20`
2. Kernel build: `#20`
3. KPM version: `ReSukiSU-x86_64-KPM-loader/0.20`
4. SHA256: `7715bbafba6744ca8f5e091694af60c1e9b38fd08846a85243be691905c4cf8f`

## Clone

```bash
git clone --recurse-submodules https://github.com/Ognisty321/WSA-Linux-Kernel.git
cd WSA-Linux-Kernel
git checkout main
git submodule update --init --recursive
```

## Build

```bash
make ARCH=x86_64 LLVM=1 -j"$(nproc)" bzImage
```

The output image is:

```text
arch/x86/boot/bzImage
```

## Install

Use the path where your unpacked WSA package is located. Do not copy the example paths literally unless they match your setup.

PowerShell example:

```powershell
$WsaDir = "C:\Path\To\WSA"
$KernelImage = "C:\Path\To\WSA-Linux-Kernel\arch\x86\boot\bzImage"

Copy-Item -Force "$WsaDir\Tools\kernel" "$WsaDir\Tools\kernel.backup"
Copy-Item -Force $KernelImage "$WsaDir\Tools\kernel"
Add-AppxPackage -ForceApplicationShutdown -ForceUpdateFromAnyVersion -Register "$WsaDir\AppxManifest.xml"
```

Start WSA and verify:

```powershell
adb connect 127.0.0.1:58526
adb shell uname -a
```

The kernel string should contain:

```text
WSA-ReSukiSU+
```

The KPM version command should return:

```text
ReSukiSU-x86_64-KPM-loader/0.20
```

## Main Changes In This Fork

1. ReSukiSU integrated into the WSA 5.15.104 x86_64 kernel base.
2. SUSFS integrated into the WSA kernel tree.
3. x86_64 ReSukiSU KPM command path enabled for Android userspace.
4. x86_64 direct KPM loader added.
5. x86_64 KPM RELA relocation handling added.
6. KernelPatch style KPM compatibility symbols added.
7. x86_64 inline hook trampoline generation added.
8. `text_poke_bp()` based install and restore added for normal inline hooks.
9. Generated executable memory is moved through `RW+NX` and `ROX`.
10. Tasks RCU grace periods are used before freeing generated executable buffers.
11. Unsafe hook targets owned by ftrace, kprobes, alternatives, jump labels or static calls are refused.

## Test Summary

The release build was tested with capability KPMs covering:

1. Basic KPM ABI.
2. Hotpatch and function pointer hook.
3. Inline hook and trampoline restore.
4. `hook_wrap` and `fp_hook_wrap`.
5. x86_64 instruction relocation cases.
6. Bad metadata rejection.
7. Unsupported syscall hook rejection.

Stress result:

```text
500 loops x 5 modules = 2500 load/control/unload cycles
final kpm num = 0
```

## KPM Compatibility

ARM64 `.kpm` binaries are not compatible with this x86_64 loader.

Source based KPMs can be ported when they avoid ARM64 assembly, ARM64 syscall numbers, ARM64 system registers and ARM64 branch helper assumptions.

Recommended x86_64 module flags:

```text
-mcmodel=kernel -mno-red-zone -mno-sse -mno-mmx -mno-avx -fno-jump-tables -fcf-protection=none -mretpoline-external-thunk -fno-pic -fno-plt -fno-common
```

## Known Limits

1. Direct syscall hook install wrappers return `EOPNOTSUPP`.
2. Existing ARM64 closed source KPM modules cannot be loaded.
3. The stock WSA test kernel does not include `KASAN`, `KCSAN`, `DEBUG_WX`, `IBT`, `CFI` or `FineIBT`.
4. Other WSA builds need separate runtime validation.
