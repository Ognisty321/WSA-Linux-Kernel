# Pull Request

## Summary

What does this PR change and why?

## Scope

Confirm that the change is in scope for this WSA x86_64 KPM port:

- [ ] Change is specific to WSA x86_64 or to the KPM loader / hook backend.
- [ ] Upstream Linux, KernelSU, ReSukiSU or SUSFS changes have already landed upstream where applicable.

## Validation

- [ ] Kernel builds cleanly with `make ARCH=x86_64 LLVM=1 -j"$(nproc)" bzImage`.
- [ ] Kernel boots in WSA and `adb shell uname -a` shows `WSA-ReSukiSU+`.
- [ ] `adb shell su -c "ksud kpm version"` reports the expected loader version.
- [ ] Capability tests for the changed area pass.
- [ ] Stress soak (`500 loops x 5 modules` or stronger) is clean for `BUG`, `WARNING`, `Oops`, GP fault, invalid opcode and use after free.

## Artifact

| Field | Value |
| --- | --- |
| Kernel build | |
| Kernel SHA256 | |
| KPM loader version | |

## Notes

Anything reviewers should know that does not fit above.
