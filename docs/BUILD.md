# Build Guide

Reproducible build for the WSA x86_64 ReSukiSU + SUSFS + KPM kernel.

## Environment

1. Linux or WSL2 with Ubuntu 22.04 or newer.
2. Clang 14 or newer with LLD.
3. The usual kernel build dependencies: `bc`, `bison`, `flex`, `libelf-dev`, `libssl-dev`, `cpio`, `kmod`, `libncurses-dev`, `python3`, `git`.

Quick install on Ubuntu:

```bash
sudo apt update
sudo apt install -y build-essential clang lld llvm bc bison flex libelf-dev \
    libssl-dev cpio kmod libncurses-dev python3 git
```

## Get the Source

```bash
git clone --recurse-submodules https://github.com/Ognisty321/WSA-Linux-Kernel.git
cd WSA-Linux-Kernel
git checkout main
git submodule update --init --recursive
```

## Build the Kernel

```bash
make ARCH=x86_64 LLVM=1 -j"$(nproc)" bzImage
```

The kernel image is at:

```text
arch/x86/boot/bzImage
```

## Verify

```bash
strings arch/x86/boot/bzImage | grep -E 'WSA-ReSukiSU|KPM-loader' | head
```

You should see the `5.15.104-...-WSA-ReSukiSU+` release string and the `ReSukiSU-x86_64-KPM-loader/0.20` marker.

## Useful Targets

| Target | What it does |
| --- | --- |
| `make defconfig` | Reset to defaults if you started editing config. |
| `make menuconfig` | Interactive config editor. |
| `make clean` | Remove build artifacts but keep config. |
| `make mrproper` | Full clean including config. |
| `make help` | Show all available targets. |

## Notable Config Options

1. `CONFIG_KSU=y` enables ReSukiSU root.
2. `CONFIG_KSU_SUSFS=y` enables SUSFS.
3. `CONFIG_KPM=y` enables the KPM API.
4. `CONFIG_KALLSYMS=y` and `CONFIG_KALLSYMS_ALL=y` enable runtime symbol lookup used by the loader.

## Build Flags for Out of Tree KPM Modules

Recommended baseline for out of tree x86_64 KPM `.kpm` objects:

```text
-mcmodel=kernel -mno-red-zone -mno-sse -mno-mmx -mno-avx -fno-jump-tables -fcf-protection=none -mretpoline-external-thunk -fno-pic -fno-plt -fno-common
```

See [KPM_PORT.md](KPM_PORT.md#kpm-build-flags) for context.

## Reproducing the Released Binary

The released binary in [`wsa-x86_64-kpm-v0.20`](https://github.com/Ognisty321/WSA-Linux-Kernel/releases/tag/wsa-x86_64-kpm-v0.20) was built with the toolchain above on Ubuntu 22.04 using `make ARCH=x86_64 LLVM=1 -j"$(nproc)" bzImage`. The kernel SHA256 is documented in the release notes. Local rebuild SHA256 may differ if the toolchain version differs.
