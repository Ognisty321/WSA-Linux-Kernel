# WSA Compatibility Matrix

This matrix tracks known-good and unsupported combinations for the WSA x86_64 ReSukiSU/SUSFS/KPM kernel.

WSA is now an archive-style target: Microsoft archived the public WSA app repository on 2025-05-20 and Store availability ended after 2025-03-05. Treat every working WSA package as a versioned input, not as an interchangeable runtime.

| WSA package/build | Windows build | Kernel base | HVCI / Memory Integrity | Manager / libksud.so | KPM status | Notes |
| --- | ---: | --- | --- | --- | --- | --- |
| `D:\WSA` local install `2026-04-28` | `26200` | 5.15.104 | on | installed `/data/adb/ksud` is old and lacks `kpm`; temporary `/data/local/tmp/ksud.kpm-capable` SHA256 `68368b32b98adb6ffb2164c6551e0684c2d193e35fbde196384f4948b89573bf` used for validation | kernel/KPM pass, installed userspace pending | `D:\WSA\Tools\kernel` replaced with kernel `#34`, SHA256 `c93249f528f515cc0d0cd2030e55791bf3c12bdc07a18748af645a4aefeeb50e`; backup saved as `D:\WSA\Tools\kernel.backup.20260427-235453`; `uname -a` reported `#34 SMP PREEMPT Mon Apr 27 23:23:45 CEST 2026`; `RUN_WSA=1 KSUD=/data/local/tmp/ksud.kpm-capable REMOTE_DIR=/data/local/tmp/kpm-test bash KernelSU/scripts/kpm-x86-preflight.sh` passed with final `modules=0` and clean dmesg scan. |
| booted local WSA before replacement `2026-04-27` | `26200` | 5.15.104 | on | installed `/data/adb/ksud` lacks `kpm` subcommand | blocked-userspace | ADB connected to `127.0.0.1:58526`; `uname -a` reported kernel `#28` with `WSA-ReSukiSU+`; `scripts/wsa-check-runtime-ksud.sh` and `KernelSU/scripts/kpm-x86-runtime-selftest.sh` stopped with a clear Manager/libksud mismatch before loading KPMs. |
| local main build `2026-04-27` | `26200` | 5.15.104 | on | release `ksud` SHA256 `68368b32b98adb6ffb2164c6551e0684c2d193e35fbde196384f4948b89573bf`, guard pass | build pass, live pass with temporary `ksud` | Kernel `#34`, SHA256 `c93249f528f515cc0d0cd2030e55791bf3c12bdc07a18748af645a4aefeeb50e`; sidecar manifest verifies the current WSA commit, ReSukiSU submodule, helper script hashes and artifact SHA; host preflight and live WSA preflight passed. |
| `MicrosoftCorporationII.WindowsSubsystemForAndroid_2407.40000.4.0_x64__8wekyb3d8bbwe` | `26200` | 5.15.104 | on | release `ksud` SHA256 `68368b32b98adb6ffb2164c6551e0684c2d193e35fbde196384f4948b89573bf` | pass | Validated locally with kernel `#30`, SHA256 `037b9507707bffca33c56cc421b5ff7085f8ec8b8f3d2abedb93072bdadfae46`, `scripts/kpm-x86-preflight.sh RUN_WSA=1` and `scripts/wsa-kpm-boot-smoke.sh`. |
| 2407-style known-good local package | record exact package version | 5.15.104 | off | x86_64 KPM-capable ReSukiSU Manager | expected pass | Same package family as the validated HVCI-on row; validate separately before release claims. |
| Store-updated or unknown WSA package | unknown | unknown | any | unknown | unsupported | Capture package SHA/build before debugging. |

For each release candidate, add a row with:

1. Windows build from `winver`.
2. WSA package full name and package SHA256.
3. HVCI state from Windows Security.
4. `adb shell uname -a`.
5. `adb shell su -c "ksud kpm doctor --json"`.
6. `adb shell su -c "ksud kpm audit --json"` after a load/control/unload cycle.
7. `KernelSU/scripts/check-manager-kpm-x86.sh` result for the Manager APK used in that row.
8. `scripts/wsa-check-runtime-ksud.sh` result.
9. If live validation is blocked before KPM load, record the exact `ksud` error and do not promote the row to `pass`.
