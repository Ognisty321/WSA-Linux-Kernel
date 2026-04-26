# Contributing

Thanks for your interest in this project. The fork is open to contributions that keep the WSA x86_64 KPM port stable and easy to install.

## Before You Start

1. Read [docs/KPM_PORT.md](docs/KPM_PORT.md) for the technical scope of the x86_64 KPM port.
2. Read [docs/BUILD.md](docs/BUILD.md) and confirm you can reproduce the released kernel locally.
3. Search the [issue tracker](https://github.com/Ognisty321/WSA-Linux-Kernel/issues) for an existing report before opening a new one.

## Reporting Bugs

Use the [bug report template](https://github.com/Ognisty321/WSA-Linux-Kernel/issues/new?template=bug_report.yml). Include:

1. WSA version.
2. `adb shell uname -a` output.
3. `adb shell su -c "ksud kpm version"` output.
4. Relevant `dmesg` slice.
5. Whether Memory Integrity was on or off on the host.

## Proposing Changes

1. Fork this repository.
2. Create a feature branch from `main`.
3. Keep changes scoped to the WSA x86_64 KPM port. Upstream Linux, upstream KernelSU, upstream ReSukiSU and upstream SUSFS changes should land in their respective upstreams first.
4. Build the kernel with the toolchain documented in [docs/BUILD.md](docs/BUILD.md) and confirm the kernel boots in WSA.
5. Run the capability and stress tests described in [docs/KPM_PORT.md](docs/KPM_PORT.md#validation-done).
6. Open a pull request with a clear description, the new kernel SHA256 and a `dmesg` excerpt that shows your tests passed.

## Coding Style

1. Follow the existing kernel code style for files inside the kernel tree.
2. Documentation files are Markdown and follow [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) style for `CHANGELOG.md`.
3. Commits should have descriptive subject lines and reference relevant files when useful.

## Validation Expectations

A change to the KPM loader, hook backend, ELF parser or supercall path should ship with:

1. Updated capability tests inside `KernelSU/kernel/kpm`.
2. A `dmesg` excerpt that shows the new tests passing on a real WSA boot.
3. Stress soak result equal to or better than the documented `500 loops x 5 modules = 2500 cycles` baseline.
4. Confirmation that the malformed metadata, syscall hook unsupported and atomic context refusal paths still behave as documented.

## License

By contributing, you agree that your contributions are licensed under the GPL-2.0 license that covers the kernel tree, plus the upstream KernelSU license for files inside `KernelSU/`.
