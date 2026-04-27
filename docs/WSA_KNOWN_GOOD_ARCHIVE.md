# Known-Good Archive Story

The WSA kernel release is reproducible only when the full runtime bundle is captured. A release note or local archive should keep these pieces together:

1. WSA package or unpacked WSA directory identifier.
2. Windows build and HVCI state used for validation.
3. Kernel artifact SHA256.
4. `.config` SHA256 and selected KSU/KPM/SUSFS config lines.
5. `WSA-Linux-Kernel` commit and dirty state.
6. `KernelSU` submodule commit and dirty state.
7. `susfs4ksu` commit or branch used by the build script.
8. Clang, LLD, Rust and Cargo versions.
9. ReSukiSU Manager version, release `ksud` SHA256 and confirmation that `libksud.so` contains the x86_64 `ksud kpm` path.
10. SHA256 of `KernelSU/scripts/check-manager-kpm-x86.sh`, `KernelSU/scripts/fuzz-kpm-x86-smoke.sh` and `KernelSU/tools/kpm-x86-fuzz/kpm_elf_fuzz.c`.
11. Boot smoke result and dmesg scan result.

Use `scripts/wsa-release-manifest.sh arch/x86/boot/bzImage` after a build. Store its output next to the kernel binary and paste the SHA256 into the release notes.

Minimum known-good verification:

```powershell
adb shell uname -a
adb shell su -c "ksud kpm doctor --json"
adb shell su -c "ksud kpm audit --json"
```

For a runtime smoke run from WSL or another host with `adb`:

```bash
ADB="/mnt/d/Programy/Path Tools/adb.exe" ADB_TARGET=127.0.0.1:58526 LOOPS=5 \
  bash scripts/wsa-kpm-boot-smoke.sh
```

The smoke script pushes `control_kpm.kpm`, then checks load, info, control, audit, unload, final `kpm num = 0` and a fresh `dmesg` scan. It removes the sample `.kpm` from `/data/adb/kpm` on exit so the test module does not autoload on the next WSA boot.
