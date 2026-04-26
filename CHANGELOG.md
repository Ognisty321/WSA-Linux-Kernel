# Changelog

All notable changes to this WSA x86_64 ReSukiSU + SUSFS + KPM kernel are documented here.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [v0.20] - 2026-04-26

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

[v0.20]: https://github.com/Ognisty321/WSA-Linux-Kernel/releases/tag/wsa-x86_64-kpm-v0.20
