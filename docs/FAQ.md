# FAQ

## My ARM64 KPM does not load. Why?

ARM64 `.kpm` binaries are compiled for a different ELF machine and use AArch64 relocations, so they cannot load on this x86_64 kernel. KPMs with C source can be ported by rebuilding for x86_64. See [KPM_PORT.md](KPM_PORT.md#kpm-build-flags) for recommended compiler flags and [../KernelSU/docs/KPM_X86_64_PORTING.md](../KernelSU/docs/KPM_X86_64_PORTING.md) for the source-level checklist.

## ReSukiSU Manager shows `Unsupported` after a Manager update

The Manager ships its own `libksud.so`. After a Manager upgrade, Android may overwrite that library with a stock build that does not handle the `kpm` subcommand on x86_64. The kernel side is unaffected if `adb shell su -c "ksud kpm version"` still returns `ReSukiSU-x86_64-KPM-loader/0.20`.

Before reinstalling, check the APK or extracted library:

```bash
KernelSU/scripts/check-manager-kpm-x86.sh /path/to/ReSukiSU-Manager.apk
```

Either reinstall the previous known-good Manager APK, or install a Manager build that carries `lib/x86_64/libksud.so` with the x86_64 KPM path.

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

The kernel string must contain `WSA-ReSukiSU+`. The KPM version must read `ReSukiSU-x86_64-KPM-loader/0.20`.

The `0.20` value is the x86_64 KPM loader runtime/ABI marker. It can stay unchanged across WSA kernel release tags such as `wsa-x86_64-kpm-v0.21`.

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

## Why is direct syscall hook install disabled?

A direct `sys_call_table` hook on x86_64 carries known integrity hazards on FineIBT, CFI and ftrace owned syscall slots. In this release the API surface is exposed as wrappers, but install calls return `EOPNOTSUPP` rather than ship a backend that has not been fully validated. A future release may enable a validated path.
