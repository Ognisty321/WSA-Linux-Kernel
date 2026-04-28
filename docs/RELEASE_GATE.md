# WSA x86_64 KPM Release Gate

This checklist defines the minimum evidence required before a WSA x86_64 KPM kernel artifact is described as a known-good release.

## Artifact Coupling

A release is valid only when these artifacts are recorded together:

1. Kernel artifact path, SHA256 and `uname -a` output.
2. WSA-Linux-Kernel commit and dirty state.
3. KernelSU/ReSukiSU submodule commit and dirty state.
4. KPM loader marker and x86_64 ABI version.
5. Manager artifact version and SHA256.
6. Android x86_64 `libksud.so` or release `ksud` SHA256.
7. WSA package full name, Windows build and Memory Integrity state.

Do not publish a release as known-good when the release tag, loader marker, KernelSU submodule, Manager artifact or manifest point at different validation states.

## Required Commands

Generate and verify the sidecar manifest next to the exact kernel file that will be shipped:

```bash
scripts/wsa-release-manifest.sh /path/to/kernel > /path/to/BUILD_INFO.txt
scripts/wsa-verify-release-manifest.sh /path/to/BUILD_INFO.txt /path/to/kernel
```

Verify the Manager packaging path before pairing it with the kernel:

```bash
KernelSU/scripts/check-manager-kpm-x86.sh /path/to/ReSukiSU-Manager.apk
```

Capture live WSA diagnostics from the installed artifact:

```bash
adb shell su -c "ksud kpm version"
adb shell su -c "ksud kpm version --json"
adb shell su -c "ksud kpm doctor --json"
adb shell su -c "ksud kpm audit --json"
adb shell su -c "ksud kpm num"
```

Run the KPM preflight and boot smoke on the same WSA install:

```bash
cd KernelSU
RUN_WSA=1 ADB="/mnt/d/Programy/Path Tools/adb.exe" ADB_TARGET=127.0.0.1:58526 \
  KSUD=/data/adb/ksud REMOTE_DIR=/data/local/tmp/kpm-test CONTROL_LOOPS=20 \
  bash scripts/kpm-x86-preflight.sh
cd ..
ADB="/mnt/d/Programy/Path Tools/adb.exe" ADB_TARGET=127.0.0.1:58526 \
  bash scripts/wsa-kpm-boot-smoke.sh
```

## Release Notes Fields

Release notes must include:

1. Kernel artifact SHA256.
2. `BUILD_INFO.txt` SHA256.
3. Manager APK SHA256.
4. Android x86_64 `ksud` or `libksud.so` SHA256.
5. `ksud kpm version` output.
6. `ksud kpm doctor --json` output or attached artifact.
7. `ksud kpm audit --json` output or attached artifact.
8. Live load/control/unload result.
9. Final `ksud kpm num` result.
10. Fresh `dmesg` failure scan result.

## Debug Validation

Stock WSA validation is not a substitute for debug-kernel validation. The release may still be shipped as a stock release, but the release notes must state whether these rows are done or pending:

1. W^X and generated executable memory under `DEBUG_WX`.
2. Lockdep and `DEBUG_ATOMIC_SLEEP`.
3. RCU and list lifetime checks.
4. KFENCE, `DEBUG_KMEMLEAK` and optional `KASAN_VMALLOC`.
5. KCSAN where supported by the WSA base.
6. ftrace, kprobe, alternatives, jump-label and static-call negative targets.
7. Longer ELF fuzzing beyond the smoke corpus.

Use `docs/KPM_DEBUG_VALIDATION.md` for the detailed matrix and result template.

## Module Compatibility

The release notes must distinguish loader conformance from module ecosystem compatibility. Sample KPM modules prove the loader path; real modules need separate rows in `docs/KPM_MODULE_COMPATIBILITY.md` with artifact SHA256, checker output, live WSA output and `dmesg` evidence.

Modules that require 32-bit compat syscall wrapping remain `blocked-abi` until the x86_64 ABI exposes a tested compat wrapper feature bit.
