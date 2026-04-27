# WSA Compatibility Matrix

This matrix tracks known-good and unsupported combinations for the WSA x86_64 ReSukiSU/SUSFS/KPM kernel.

WSA is now an archive-style target: Microsoft archived the public WSA app repository on 2025-05-20 and Store availability ended after 2025-03-05. Treat every working WSA package as a versioned input, not as an interchangeable runtime.

| WSA package/build | Windows build | Kernel base | HVCI / Memory Integrity | Manager / libksud.so | KPM status | Notes |
| --- | ---: | --- | --- | --- | --- | --- |
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
