# KPM Module Compatibility Tracker

This tracker separates verified WSA x86_64 modules from modules that only look portable from source review. A module is compatible only after the x86_64 artifact passes the local ELF checker and a live WSA load/control/unload cycle.

## Gate

Run these checks before adding or updating a module row:

```bash
cd KernelSU
scripts/check-kpm-module-x86.sh /path/to/module.kpm
RUN_WSA=1 ADB="/mnt/d/Programy/Path Tools/adb.exe" ADB_TARGET=127.0.0.1:58526 \
  bash scripts/kpm-x86-preflight.sh
```

For one-off module validation, the minimum live flow is:

```bash
adb push /path/to/module.kpm /data/local/tmp/module.kpm
adb shell su -c "mkdir -p /data/adb/kpm && chmod 700 /data/adb/kpm"
adb shell su -c "cp /data/local/tmp/module.kpm /data/adb/kpm/module.kpm"
adb shell su -c "ksud kpm doctor --json"
adb shell su -c "ksud kpm load /data/adb/kpm/module.kpm"
adb shell su -c "ksud kpm audit --json"
adb shell su -c "ksud kpm unload module"
adb shell su -c "ksud kpm num"
```

Use the actual module name from `ksud kpm info` when unloading.

## Status Values

| Status | Meaning |
| --- | --- |
| `pass` | x86_64 `.kpm` passed the checker, live WSA load/control/unload passed and dmesg stayed clean. |
| `host-pass` | x86_64 `.kpm` passed the checker and local preflight, but the current artifact still needs live WSA validation. |
| `source-candidate` | Source looks portable, but no WSA x86_64 artifact has passed live validation yet. |
| `blocked-arch` | Only an ARM64 prebuilt exists or the source depends on AArch64 instructions. |
| `blocked-wsa` | The module depends on vendor phone drivers or kernel symbols not present in WSA. |
| `blocked-abi` | The module requires a loader feature that this x86_64 ABI intentionally does not expose. |

## Current Rows

| Module | Status | Evidence | Notes |
| --- | --- | --- | --- |
| `hello_kpm_x86_64` example | `host-pass` | `scripts/check-kpm-module-x86.sh`, `scripts/kpm-x86-preflight.sh` without `RUN_WSA=1`. | Minimal load/unload ABI sample. |
| `control_kpm` example | `host-pass` | Same example preflight evidence. | Validates `.kpm.ctl0` return handling. |
| `control_owner` example | `host-pass` | Same example preflight evidence. | Validates ownership tagging from `.kpm.ctl0`. |
| `inline_hook` example | `host-pass` | Same example preflight evidence. | Validates inline hook install and restore on supported targets. |
| `fp_hook` example | `host-pass` | Same example preflight evidence. | Validates function pointer hook install and restore. |
| `hotpatch` example | `host-pass` | Same example preflight evidence. | Validates transactional hotpatch path. |
| `failure_cases` example | `host-pass` | Same example preflight evidence. | Validates refusal and cleanup paths. |
| ARM64-only prebuilt modules | `blocked-arch` | Checker rejects non-x86_64 ELF. | Rebuild from source is required. |
| Direct syscall hook modules | `blocked-abi` | `hook_syscalln`, `fp_wrap_syscalln`, `inline_wrap_syscalln` return `EOPNOTSUPP`. | Wrapper symbols exist for compatibility, but install is intentionally refused. |
| Phone vendor driver modules | `blocked-wsa` | WSA does not ship the target vendor drivers. | Examples include modules built around device-specific battery, display, freezer or SoC drivers. |

## Row Template

| Module | Status | Evidence | Notes |
| --- | --- | --- | --- |
| `name` | `source-candidate` | `scripts/check-kpm-module-x86.sh` SHA256 output, WSA package, Windows build, kernel SHA256, `ksud kpm audit --json`, dmesg scan. | Source URL, commit, required symbols and any disabled feature. |

Keep the row tied to one built `.kpm` SHA256. Rebuilds with different compiler flags need a new evidence note.
