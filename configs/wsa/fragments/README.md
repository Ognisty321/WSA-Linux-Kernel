# WSA x86_64 Validation Fragments

These fragments are optional overlays for ReSukiSU/SUSFS/KPM validation builds.
Apply them on top of the WSA x86_64 base config with `scripts/kconfig/merge_config.sh`,
then run `make ARCH=x86_64 LLVM=1 olddefconfig`.

| Fragment | Purpose |
| --- | --- |
| `wsa-x86_64-debug.config` | Locking, list, memory lifetime, stacktrace and W^X diagnostics. |
| `wsa-x86_64-sanitize.config` | KASAN/KCSAN/KFENCE/UBSAN-style short repro builds where supported. |
| `wsa-x86_64-ibt.config` | Experimental IBT/CFI/FineIBT probe for debug or QEMU-style validation. |

Record any dropped symbols from `olddefconfig` in the release or validation notes.

Use the local checker to produce a kept/dropped symbol report without touching the main `.config`:

```bash
scripts/wsa-validate-config-fragment.sh configs/wsa/fragments/wsa-x86_64-debug.config
```

Set `BUILD=1` to build a validation `bzImage` under `out/wsa-validation/<fragment>/` and generate `BUILD_INFO.txt` plus `SHA256SUMS.txt` for that debug artifact.

Current 5.15.104 WSA base check:

1. `wsa-x86_64-debug.config` keeps `DEBUG_WX`, `PROVE_LOCKING`, `DEBUG_LIST`, `DEBUG_KMEMLEAK` and `KFENCE`.
2. `wsa-x86_64-sanitize.config` keeps `KASAN`, `UBSAN`, `DEBUG_LIST` and `KFENCE`; `KCSAN` is dependency-gated out on this base.
3. `wsa-x86_64-ibt.config` keeps `LTO_CLANG_THIN`; IBT/CFI/FineIBT symbols are dependency-gated out on this base and still need a newer or differently configured validation kernel.
