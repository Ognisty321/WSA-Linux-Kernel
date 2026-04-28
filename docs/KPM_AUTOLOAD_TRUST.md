# KPM Autoload Trust Policy

The current autoload guard protects the boot path by requiring `/data/adb/kpm` to be a real directory with mode `700`, rejecting symlinks and non-regular `.kpm` files, and honoring `/data/adb/kpm.disabled` as the recovery marker.

This document defines the next policy layer. It is a design target until the corresponding `ksud kpm trust` commands and kernel/userspace checks are implemented.

## Goals

1. Prevent accidental boot-time loading of unknown `.kpm` files.
2. Keep recovery possible with `/data/adb/kpm.disabled`.
3. Make support reports traceable to module hashes, loader ABI and feature bits.
4. Avoid claiming cryptographic trust for files that can still be modified by a root user.

## Allowlist Model

Autoload should accept a module only when all checks pass:

1. The file is a regular `.kpm` inside `/data/adb/kpm`.
2. The directory ownership and mode checks pass.
3. The module SHA256 appears in `/data/adb/kpm.trust`.
4. The recorded loader ABI is compatible with the running loader.
5. The recorded feature bits are a subset of the running loader feature bits.

The trust database format should be line-oriented so it can be inspected during recovery:

```text
sha256=<hex> name=<module> version=<version> abi=<n> features=<hex> added_utc=<iso8601>
```

## Commands

The userspace interface should be:

```bash
ksud kpm trust add /data/adb/kpm/module.kpm
ksud kpm trust remove <sha256-or-name>
ksud kpm trust list
ksud kpm trust check /data/adb/kpm/module.kpm
```

`trust add` should run the same ELF and ABI validation used by `scripts/check-kpm-module-x86.sh` before writing a row.

## Crash-Loop Recovery

Autoload should record the last attempted set before loading modules:

```text
/data/adb/kpm.last_attempt
/data/adb/kpm.last_success
```

If the previous boot recorded an attempt but not a success marker, the next boot should skip autoload, create `/data/adb/kpm.disabled`, and report the reason through `ksud kpm autoload-status`.

## Release Modules

Release modules may add detached signatures later, but hash allowlisting should remain the baseline because it is easy to audit on WSA and does not depend on a key distribution channel. Signed modules should still record the final `.kpm` SHA256 in `docs/KPM_MODULE_COMPATIBILITY.md`.
