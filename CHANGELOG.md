# Changelog

All notable changes to this WSA x86_64 ReSukiSU + SUSFS + KPM kernel are documented here.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

### Added

1. Native x86_64 syscall-table wrapper backend for `hook_syscalln`, `fp_wrap_syscalln` and `inline_wrap_syscalln`; compat syscall wrapping remains unsupported.
2. x86_64 KPM module compatibility checker, module evidence template and documented compatibility matrix for real `.kpm` candidates.
3. WSA release manifest verifier plus runtime `ksud` checker so kernel artifacts, sidecar manifests and installed userspace are validated together.
4. WSA boot smoke script coverage for installed `/data/adb/ksud`, load / info / control / audit / unload loops, final module count and fresh `dmesg` failure scanning.
5. WSA debug validation matrix and config fragment validator for future KASAN, KCSAN, DEBUG_WX, IBT, CFI, FineIBT and lockdep builds.
6. KPM autoload recovery documentation and disable marker flow for bad boot-time module sets.
7. ReSukiSU Manager x86_64 packaging guard documentation and preflight coverage for `libksud.so` carrying the `ksud kpm` path.
8. x86_64 KPM sample and test coverage for control-owner attribution and syscall wrapper behavior.
9. x86_64 KPM security issue template and reporting requirements for WSA-specific loader, module and Manager reports.
10. Expanded KPM ELF fuzz smoke corpus plus recorded fuzz harness provenance in release manifests.
11. x86_64 KPM patch hygiene and upstreaming documentation for future ReSukiSU rebases.

### Changed

1. Bumped the current `main` KPM loader marker to `ReSukiSU-x86_64-KPM-loader/0.21` for the native x86_64 syscall wrapper ABI.
2. Advanced the `KernelSU` submodule from ReSukiSU `a0d26e23` to `79a5ae91`, including hook hardening, native syscall wrappers, Manager guards, CI formatting fixes and module-context ownership hardening.
3. Expanded release provenance capture with kernel tag, dirty-state flags, Windows build, HVCI state, WSA package metadata, release `ksud` SHA256 and helper-script SHA256 values.
4. Updated README, build, install, FAQ, KPM porting, module compatibility and known-good archive documentation around the `0.20` published loader marker versus the current `0.21` source marker.
5. Updated the WSA compatibility matrix for the local `D:\WSA` install on Windows build `26200` with Memory Integrity enabled.
6. Clarified that Manager support requires an x86_64 `ksud kpm` userspace path, not only a KPM-capable kernel.
7. Refreshed build, module compatibility and debug validation docs to mark the exact WSA config flow, sample KPM live WSA pass and installed `/data/adb/ksud` validation.

### Fixed

1. Hardened x86_64 KPM hook validation and error reporting so unsafe hook targets return specific failures instead of ambiguous loader errors.
2. Made KPM module context ownership fail closed for load, unload and control paths when the owner context cannot be allocated.
3. Preserved failed modules as resident when failed init or duplicate registration leaves active hooks or callbacks behind.
4. Stabilized ReSukiSU x86_64 ABI and Manager guard CI paths so local and GitHub runner checks use the same expected inputs.
5. Applied clang-format fixes required by the GitHub runner for the KPM loader sources.
6. Made live selftests stop with a clear installed-userspace mismatch when `/data/adb/ksud` lacks the `kpm` subcommand.

### Verified

1. Local main build `#36` with loader `ReSukiSU-x86_64-KPM-loader/0.21` passed host KPM preflight, live WSA KPM preflight and installed `/data/adb/ksud` boot smoke.
2. Native `syscall_wrap` load / unload was validated on the live WSA kernel.
3. Final live module count stayed at `0` after repeated KPM load / control / unload loops.
4. Fresh live `dmesg` scans were clean for `BUG`, `WARNING`, `Oops`, general protection faults, invalid opcodes and use-after-free markers.
5. Installed `/data/adb/ksud` was upgraded to a KPM-capable x86_64 build with SHA256 `3f94c8ffaa8e2d030a18f6fc72819dd34ef5c625be31d1c2dcadb672d6f4c833`.

### Artifact

1. Local kernel candidate: `5.15.104-windows-subsystem-for-android-20230927-WSA-ReSukiSU+`
2. Build: `#36`
3. KPM loader: `ReSukiSU-x86_64-KPM-loader/0.21`
4. Kernel SHA256: `f6c7694e5d1c04f063ba6229ddf190634664c62b1fe6c62fbe6c6ec625819af1`
5. Sidecar manifest SHA256: `9647cd1de0788e2ede8e2af6a4e28d015845e971c96a741a30db5d0c2b2f6991`
6. Manifest source state: WSA commit `fb64860b3e8e`, ReSukiSU submodule commit `b7b1e740195d`, both dirty at manifest generation because the validated tree was committed afterward.
7. WSA package: `MicrosoftCorporationII.WindowsSubsystemForAndroid_2407.40000.4.0_x64__8wekyb3d8bbwe`
8. Windows build: `26200`, Memory Integrity on

## [v0.21] - 2026-04-27

### Added

1. WSA release provenance documentation tying the public `v0.21` artifact to the exact WSA kernel commit, ReSukiSU submodule commit, loader marker and local validation environment.
2. CI sidecar manifest upload for WSA kernel builds.
3. ReSukiSU workflow guards for missing fork secrets, including CI signing fallback and Crowdin skip behavior.
4. x86_64 KPM ABI diagnostics in ReSukiSU CI.

### Changed

1. Refreshed the WSA x86_64 KPM release artifact and provenance metadata.
2. Advanced the WSA kernel release tag to `wsa-x86_64-kpm-v0.21`.
3. Pinned the public release to WSA kernel commit `84a389e01` and ReSukiSU submodule commit `a0d26e23`.
4. Kept the KPM loader marker at `ReSukiSU-x86_64-KPM-loader/0.20` because it is the loader runtime/ABI marker, not the WSA kernel release number.
5. Removed the obsolete public `wsa-x86_64-kpm-v0.20` GitHub release and remote tag after publishing the refreshed `v0.21` artifact.

### Verified

1. GitHub `Build Manager`, `KPM x86_64 ABI check`, `ClangFormat check`, `Crowdin Action` and WSA `Build kernel` workflows passed for the pinned release source state.
2. `actionlint` passed for the ReSukiSU and WSA workflow sets used by the release.

### Artifact

1. Kernel: `5.15.104-windows-subsystem-for-android-20230927-WSA-ReSukiSU+`
2. Build: `#30`
3. KPM loader: `ReSukiSU-x86_64-KPM-loader/0.20`
4. Kernel SHA256: `037b9507707bffca33c56cc421b5ff7085f8ec8b8f3d2abedb93072bdadfae46`
5. WSA package: `MicrosoftCorporationII.WindowsSubsystemForAndroid_2407.40000.4.0_x64__8wekyb3d8bbwe`
6. Windows build: `26200`, Memory Integrity on

## v0.20 - 2026-04-26 (withdrawn)

The public GitHub release and tag were withdrawn because they pointed at an outdated `ReSukiSU 0f56456` snapshot and were replaced by the refreshed `wsa-x86_64-kpm-v0.21` release. This entry is kept only as a historical local pre-release record.

### Added

1. WSA 5.15.104 x86_64 kernel base with ReSukiSU root and SUSFS hide.
2. x86_64 KPM runtime in the kernel tree, replacing the ARM64 `kpimg` boot time patching flow that does not apply to WSA.
3. x86_64 `ET_REL` KPM ELF loader with bounds checks on header, sections, strings, relocations and entry points.
4. x86_64 RELA relocation handling for `R_X86_64_64`, `R_X86_64_PC32`, `R_X86_64_PLT32`, `R_X86_64_32`, `R_X86_64_32S`, `R_X86_64_GOTPCREL`, `R_X86_64_GOTPCRELX`, `R_X86_64_REX_GOTPCRELX`.
5. KernelPatch style compatibility surface: `kpver`, `kver`, `kp_malloc`, `kp_free`, `compat_copy_to_user`, `symbol_lookup_name`, `hotpatch`, `hook`, `hook_wrap`, `fp_hook`, `fp_hook_wrap`.
6. x86_64 inline hook backend with kernel `insn` decoder for length and RIP relative fixup.
7. `text_poke_bp()` based install and restore for normal `JMP rel32` hooks under `text_mutex`.
8. `RW+NX` to `ROX` page transitions for trampolines and wrapper stubs.
9. `synchronize_rcu_tasks_rude()` plus `synchronize_rcu_tasks()` before generated executable buffers are freed.
10. Refusal of unsafe or conflicting hook targets owned by ftrace, kprobes, alternatives, jump labels or static calls.
11. Refusal of patching from IRQ or atomic context.
12. Android x86_64 `ksud kpm` command path so ReSukiSU Manager can drive the loader.

### Verified

1. `500` loops across `5` capability modules, total `2500` load / control / unload cycles.
2. Final `kpm num = 0`.
3. Capability checks: basic ABI, hotpatch, function pointer hook, inline hook, trampoline restore, `hook_wrap`, `fp_hook_wrap`, x86_64 instruction relocation, malformed metadata rejection, unsupported syscall hook rejection.
4. Kernel log clean for `BUG`, `WARNING`, `Oops`, general protection faults, invalid opcode reports and use after free reports.

### Known Limits

1. Direct syscall hook install returns `EOPNOTSUPP`. The wrapper symbols are present for compatibility.
2. ARM64 `.kpm` binaries cannot load on x86_64.
3. The stock WSA configuration does not enable `KASAN`, `KCSAN`, `DEBUG_WX`, `IBT`, `CFI` or `FineIBT`. Validation rows that need these configs require a separate debug kernel.

### Artifact

1. Kernel: `5.15.104-windows-subsystem-for-android-20230927-WSA-ReSukiSU+`
2. Build: `#20`
3. KPM loader: `ReSukiSU-x86_64-KPM-loader/0.20`
4. Kernel SHA256: `7715bbafba6744ca8f5e091694af60c1e9b38fd08846a85243be691905c4cf8f`

[Unreleased]: https://github.com/Ognisty321/WSA-Linux-Kernel/compare/wsa-x86_64-kpm-v0.21...main
[v0.21]: https://github.com/Ognisty321/WSA-Linux-Kernel/releases/tag/wsa-x86_64-kpm-v0.21
