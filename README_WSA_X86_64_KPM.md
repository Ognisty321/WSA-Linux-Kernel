# ReSukiSU KPM for WSA x86_64

Author and maintainer: Ognisty321

This fork adds a ReSukiSU KPM runtime for Windows Subsystem for Android on x86_64.
The goal is a real KPM loader and hook backend for WSA, not only a manager status string.

## Current Status

1. Target kernel: WSA Linux `5.15.104-windows-subsystem-for-android-20230927`.
2. Tested build: `#20`.
3. KPM version string: `ReSukiSU-x86_64-KPM-loader/0.20`.
4. Kernel artifact SHA256: `7715bbafba6744ca8f5e091694af60c1e9b38fd08846a85243be691905c4cf8f`.
5. Runtime test result: `500` loops across `5` KPM capability modules, for `2500` load, control and unload cycles, final `kpm num = 0`.

## What Works

1. x86_64 `ET_REL` KPM loading with `.kpm.info`, `.kpm.init`, `.kpm.exit`, optional `.kpm.ctl0` and optional `.kpm.ctl1`.
2. Common x86_64 RELA relocation handling, including `R_X86_64_64`, `PC32`, `PLT32`, `32`, `32S`, `PC64`, `GOTPCREL`, `GOTPCRELX` and `REX_GOTPCRELX`.
3. KernelPatch style compatibility symbols for memory helpers, symbol lookup, hotpatch, inline hook, function pointer hook, `hook_wrap` and `fp_hook_wrap`.
4. Inline hook trampolines for x86_64 with RIP relative relocation through the kernel instruction decoder path.
5. Normal in range inline hook install and restore through x86 `text_poke_bp()`.
6. Generated trampoline and wrapper pages transition through `RW+NX` and `ROX`, with Tasks RCU synchronization before executable buffers are freed.
7. Manager integration through the existing ReSukiSU KPM command path on Android x86_64.

## Known Limits

1. ARM64 `.kpm` binaries are not compatible with this loader.
2. Existing KPMs need x86_64 builds. Source modules have the best chance to work.
3. ARM64 assembly, ARM64 syscall numbers and ARM64 branch helpers need module specific porting.
4. Direct syscall hook wrappers are exported for compatibility, but install calls intentionally return `EOPNOTSUPP` on this WSA build.
5. This WSA kernel does not enable `KASAN`, `KCSAN`, `DEBUG_WX`, `IBT`, `CFI` or `FineIBT`, so those validation rows require a separate debug kernel.

## Build

```bash
cd /home/ognisty321/wsa-kernel-resukisu-wsa2407/WSA-Linux-Kernel
make ARCH=x86_64 LLVM=1 -j$(nproc) bzImage
```

The kernel image is produced at:

```text
arch/x86/boot/bzImage
```

## Install on WSA

1. Shut down WSA fully.
2. Copy `arch/x86/boot/bzImage` to `D:\WSA\Tools\kernel`.
3. Re register the unpacked WSA package.
4. Start ReSukiSU Manager.
5. Confirm the running kernel with `adb shell uname -a`.

Example PowerShell:

```powershell
Copy-Item -Force "\\wsl$\Ubuntu\home\ognisty321\wsa-kernel-resukisu-wsa2407\WSA-Linux-Kernel\arch\x86\boot\bzImage" "D:\WSA\Tools\kernel"
Add-AppxPackage -ForceApplicationShutdown -ForceUpdateFromAnyVersion -Register "D:\WSA\AppxManifest.xml"
adb connect 127.0.0.1:58526
adb shell uname -a
```

## Test

The expected KPM version response is:

```text
ReSukiSU-x86_64-KPM-loader/0.20
```

The tested capability set covers:

1. Basic KPM ABI.
2. Hotpatch and function pointer hook.
3. Inline hook and trampoline restore.
4. `hook_wrap` and `fp_hook_wrap`.
5. x86_64 instruction relocation cases.
6. Malformed metadata rejection.
7. Unsupported syscall hook rejection.

After a clean run, `kpm num` must return `0`, and `dmesg` should not contain kernel `BUG`, `WARNING`, `Oops`, general protection faults, invalid opcode reports or use after free reports.

## KPM Build Flags

KPM modules should be built as x86_64 non PIC RELA objects. A working baseline is:

```text
-mcmodel=kernel -mno-red-zone -mno-sse -mno-mmx -mno-avx -fno-jump-tables -fcf-protection=none -mretpoline-external-thunk -fno-pic -fno-plt -fno-common
```

## Repository Layout

1. The WSA kernel fork carries the Microsoft WSA kernel integration.
2. `KernelSU` is ReSukiSU and should point to the matching x86_64 KPM branch.
3. The main loader implementation lives in `KernelSU/kernel/kpm/kpm_loader_x86_64.c`.
4. Detailed ReSukiSU side notes live in `KernelSU/docs/WSA_X86_64_KPM.md`.
