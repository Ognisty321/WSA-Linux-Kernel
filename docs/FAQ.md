# FAQ

## My ARM64 KPM does not load. Why?

ARM64 `.kpm` binaries are compiled for a different ELF machine and use AArch64 relocations, so they cannot load on this x86_64 kernel. KPMs with C source can be ported by rebuilding for x86_64. See [KPM_PORT.md](KPM_PORT.md#kpm-build-flags) for recommended compiler flags and [../KernelSU/docs/KPM_X86_64_PORTING.md](../KernelSU/docs/KPM_X86_64_PORTING.md) for the source-level checklist.

Before trying a rebuilt module on WSA, run:

```bash
KernelSU/scripts/check-kpm-module-x86.sh /path/to/module.kpm
```

Tracked module status lives in [KPM_MODULE_COMPATIBILITY.md](KPM_MODULE_COMPATIBILITY.md).

## ReSukiSU Manager shows `Unsupported` after a Manager update

The Manager ships its own `libksud.so`. After a Manager upgrade, Android may overwrite that library with a stock build that does not handle the `kpm` subcommand on x86_64. The kernel side is unaffected if `adb shell su -c "ksud kpm version"` still returns the marker for your installed artifact, for example `ReSukiSU-x86_64-KPM-loader/0.20` on the published `v0.21` binary or `ReSukiSU-x86_64-KPM-loader/0.21` on current `main` builds.

Before reinstalling, check the APK or extracted library:

```bash
KernelSU/scripts/check-manager-kpm-x86.sh /path/to/ReSukiSU-Manager.apk
```

Either reinstall the previous known-good Manager APK, or install a Manager build that carries `lib/x86_64/libksud.so` with the x86_64 KPM path.

If the live self-test prints `/data/adb/ksud does not expose the kpm subcommand`, the running WSA userspace is still missing the KPM-capable `ksud`. Confirm it with:

```bash
ADB="/mnt/d/Programy/Path Tools/adb.exe" ADB_TARGET=127.0.0.1:58526 \
  bash scripts/wsa-check-runtime-ksud.sh
```

The kernel cannot make the userspace `kpm` command appear. Install a Manager or `libksud.so` build that passes the x86_64 guard, then rerun `RUN_WSA=1 bash KernelSU/scripts/kpm-x86-preflight.sh`.

## Manager shows `KPM Version Supported` but a hook does nothing

Manager only checks transport reachability and the loader version. A green `Supported` badge proves that `ksud kpm version` can talk to the kernel, not that any specific hook works. To diagnose:

1. Run `adb shell su -c "ksud kpm list"` and confirm your module is loaded.
2. Run `adb shell su -c "ksud kpm info <name>"` and confirm metadata.
3. Run `adb shell su -c "ksud kpm doctor --json"` and check loader, module count and KPM directory state.
4. Run `adb shell su -c "dmesg | tail -200"` and look for `kpm:` lines from the loader.

## How do I disable Memory Integrity (HVCI) on Windows?

Open Windows Security, go to Device security, then Core isolation details, and toggle Memory Integrity off. Reboot Windows. To verify from PowerShell:

```powershell
Get-CimInstance -ClassName Win32_DeviceGuard `
  -Namespace root\Microsoft\Windows\DeviceGuard |
  Select-Object SecurityServicesRunning
```

`SecurityServicesRunning` should not contain `2`. If a corporate policy keeps it on, this kernel may not be usable on that machine.

## WSA does not boot after replacing the kernel

Roll back to your backup:

```powershell
WsaClient.exe /shutdown
$WsaDir = "C:\Path\To\WSA"
Copy-Item -Force "$WsaDir\Tools\kernel.backup" "$WsaDir\Tools\kernel"
Add-AppxPackage -ForceApplicationShutdown -ForceUpdateFromAnyVersion -Register "$WsaDir\AppxManifest.xml"
```

If you did not make a backup, reinstall WSA from your original source.

## KPM modules stopped autoloading after a bad boot

The x86_64 `ksud` autoload path writes `/data/adb/kpm.disabled` after a boot-time KPM load failure. This prevents WSA from retrying the same bad autoload set on every boot.

After removing or fixing the broken `.kpm` files, clear the marker:

```powershell
adb shell su -c "rm -f /data/adb/kpm.disabled"
adb shell su -c "ksud kpm doctor --json"
```

`doctor` reports `autoload_disabled` and `autoload_disable_file` so you can confirm the state.

## How do I confirm KPM is actually running?

```powershell
adb connect 127.0.0.1:58526
adb shell uname -a
adb shell su -c "ksud kpm version"
adb shell su -c "ksud kpm doctor --json"
```

The kernel string must contain `WSA-ReSukiSU+`. The KPM version must match the installed artifact: `ReSukiSU-x86_64-KPM-loader/0.20` for the published `v0.21` binary, or the `kpm_loader=` value from the sidecar manifest for a local build. Current `main` source builds report `ReSukiSU-x86_64-KPM-loader/0.21`.

The loader marker is separate from WSA kernel release tags such as `wsa-x86_64-kpm-v0.21`.

## Can I use this kernel with a different WSA build?

The release was built and tested against WSA 2407 style `5.15.104` x86_64. Other WSA builds may have different `bzImage` boot expectations and need their own validation. Building from source against a matching WSA tree is the right path.

## Where do I report a bug?

Open a [bug report](https://github.com/Ognisty321/WSA-Linux-Kernel/issues/new/choose) and include:

1. WSA version.
2. Output of `adb shell uname -a`.
3. Output of `adb shell su -c "ksud kpm version"`.
4. Output of `adb shell su -c "ksud kpm doctor --json"`.
5. Relevant `dmesg` slice.
6. Whether Memory Integrity was on or off on the host.

## What syscall hook path is supported?

Native x86_64 syscall wrapping is implemented through `hook_syscalln`, `fp_wrap_syscalln` and `inline_wrap_syscalln`. Compat syscall wrapping remains unsupported on WSA x86_64 and returns `EOPNOTSUPP`. Prefer these wrapper APIs over patching syscall entry text directly.
