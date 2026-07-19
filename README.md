# WSA Linux Kernel with ReSukiSU

> A WSA 5.15 x86_64 kernel with ReSukiSU root, SUSFS and a native x86_64 KPM runtime.

[![Build kernel](https://github.com/Ognisty321/WSA-Linux-Kernel/actions/workflows/build.yml/badge.svg?branch=main)](https://github.com/Ognisty321/WSA-Linux-Kernel/actions/workflows/build.yml)
[![Latest release](https://img.shields.io/github/v/release/Ognisty321/WSA-Linux-Kernel?label=release&color=blue)](https://github.com/Ognisty321/WSA-Linux-Kernel/releases/latest)
[![License](https://img.shields.io/badge/license-GPL--2.0-lightgrey)](COPYING)

This project packages the kernel-side pieces needed to use ReSukiSU, SUSFS and KPM modules in Windows Subsystem for Android. The x86_64 KPM support is implemented in the paired [ReSukiSU fork](https://github.com/Ognisty321/ReSukiSU), which is pinned here as the `KernelSU` submodule.

## Start Here

| I want to... | Go to |
| --- | --- |
| Install the latest kernel | [Installation guide](docs/INSTALL.md) |
| Build the kernel myself | [Build guide](docs/BUILD.md) |
| Fix a boot or Manager problem | [FAQ and recovery steps](docs/FAQ.md) |
| Check whether a KPM module is compatible | [Module compatibility tracker](docs/KPM_MODULE_COMPATIBILITY.md) |
| Understand the x86_64 KPM implementation | [Technical overview](docs/KPM_PORT.md) |
| See what changed between releases | [Changelog](CHANGELOG.md) |

## What You Get

- the Microsoft WSA 5.15.104 x86_64 kernel base;
- ReSukiSU root integration with SUSFS support;
- a real x86_64 KPM loader, hook backend and native syscall wrappers;
- a paired Manager and `ksud` path for loading and controlling KPM modules;
- CI checks for kernel builds, version metadata, release manifests and Manager packaging.

## Install

1. Download the kernel and its release metadata from the [latest release](https://github.com/Ognisty321/WSA-Linux-Kernel/releases/latest).
2. Read the [installation guide](docs/INSTALL.md), including its prerequisites and rollback steps.
3. Back up your current `Tools\kernel`, verify the downloaded checksum, then replace the kernel and re-register WSA.
4. Boot WSA and verify the installation:

```console
adb shell uname -a
adb shell su -c "ksud kpm version"
adb shell su -c "ksud kpm doctor --json"
```

The kernel string should contain `WSA-ReSukiSU`. The KPM version should match the value recorded in the release manifest. The [full installation guide](docs/INSTALL.md) explains the checks and recovery procedure step by step.

## Compatibility and Limitations

- The tested target is a WSA 2407-style package with the 5.15.104 x86_64 kernel. Other packages may use a different kernel layout or ABI.
- ARM64 `.kpm` files do not run on x86_64. Modules with available source may be portable using the [ReSukiSU porting guide](KernelSU/docs/KPM_X86_64_PORTING.md).
- The Manager must contain a matching x86_64 `libksud.so`. A stock or ARM64-only Manager can report KPM as unsupported even when the kernel side is present.
- Memory Integrity has worked in the recorded WSA baseline, but behavior can vary with Windows and WSA builds. See the [FAQ](docs/FAQ.md) if hooks fail or WSA does not start.
- Native x86_64 syscall wrappers are available. Compat syscall wrapping is not supported.

Consult the [WSA compatibility matrix](docs/WSA_COMPATIBILITY_MATRIX.md) before using a different Windows or WSA version.

## Build from Source

Clone this repository with submodules so the kernel and ReSukiSU revisions stay paired. The [build guide](docs/BUILD.md) covers the required toolchain, configuration fragments, build command and artifact verification.

Do not replace the `KernelSU` submodule with an arbitrary upstream revision. The WSA kernel and ReSukiSU fork share an x86_64 KPM ABI and are released together.

## Documentation

| Document | Contents |
| --- | --- |
| [Install](docs/INSTALL.md) | Windows installation, verification and rollback |
| [Build](docs/BUILD.md) | Reproducible WSL2 and Linux builds |
| [FAQ](docs/FAQ.md) | Manager, HVCI, boot and KPM troubleshooting |
| [KPM port](docs/KPM_PORT.md) | Loader, hooks, ABI and safety model |
| [Module compatibility](docs/KPM_MODULE_COMPATIBILITY.md) | Status and evidence for x86_64 KPM modules |
| [Release gate](docs/RELEASE_GATE.md) | Required artifact, Manager and runtime evidence |
| [Debug validation](docs/KPM_DEBUG_VALIDATION.md) | KASAN, KCSAN, W^X and race-testing matrix |

## Releases and Validation

The [latest release page](https://github.com/Ognisty321/WSA-Linux-Kernel/releases/latest) is the source of truth for the current tag, kernel checksum, ReSukiSU revision, loader marker and validation status. Keeping those values with the artifact avoids stale release data in this README.

Every release candidate is expected to pass the checks in [docs/RELEASE_GATE.md](docs/RELEASE_GATE.md). Historical changes and superseded releases remain in [CHANGELOG.md](CHANGELOG.md).

## Reporting Issues

Open an issue in the [issue tracker](https://github.com/Ognisty321/WSA-Linux-Kernel/issues) and include:

```console
adb shell uname -a
adb shell su -c "ksud kpm version"
adb shell su -c "ksud kpm doctor --json"
```

Also attach the relevant `dmesg` section and note your Windows build, WSA package version and Memory Integrity state.

## Credits and License

This work builds on the Microsoft WSA Linux kernel, [KernelSU](https://github.com/tiann/KernelSU), [ReSukiSU](https://github.com/ReSukiSU/ReSukiSU), SukiSU-related research, [SUSFS](https://gitlab.com/simonpunk/susfs4ksu) and the Linux x86 text-patching infrastructure. The WSA x86_64 KPM port and packaging are maintained by Ognisty321.

The kernel is licensed under GPL-2.0. Included components retain their upstream licenses. See [COPYING](COPYING), [LICENSES](LICENSES) and [KernelSU/LICENSE](KernelSU/LICENSE).
