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

## Configure the Kernel

Start from the WSA x64 config and enable the ReSukiSU, SUSFS and KPM options used by CI:

```bash
cp configs/wsa/config-wsa-x64 .config

./scripts/config --file .config --set-str LOCALVERSION '-WSA-ReSukiSU'

./scripts/config --file .config \
  -e KSU \
  -d KSU_DEBUG \
  -e KSU_SUSFS \
  -d KSU_TRACEPOINT_HOOK \
  -d KSU_MANUAL_HOOK \
  -e KPM \
  -e KALLSYMS \
  -e KALLSYMS_ALL \
  -e KSU_SUSFS_SUS_PATH \
  -e KSU_SUSFS_SUS_MOUNT \
  -e KSU_SUSFS_SUS_KSTAT \
  -e KSU_SUSFS_SPOOF_UNAME \
  -e KSU_SUSFS_ENABLE_LOG \
  -e KSU_SUSFS_HIDE_KSU_SUSFS_SYMBOLS \
  -e KSU_SUSFS_SPOOF_CMDLINE_OR_BOOTCONFIG \
  -e KSU_SUSFS_OPEN_REDIRECT \
  -e KSU_SUSFS_SUS_MAP \
  -e NAMESPACES -e NET_NS -e USER_NS -e PID_NS -e UTS_NS -e IPC_NS \
  -e CGROUPS -e MEMCG -e CGROUP_PIDS -e CGROUP_BPF \
  -e OVERLAY_FS \
  -e NETFILTER_XT_TARGET_MASQUERADE -e NF_NAT \
  -e IP_NF_NAT -e IP_NF_TARGET_MASQUERADE

make ARCH=x86_64 LLVM=1 olddefconfig
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

You should see the `5.15.104-...-WSA-ReSukiSU+` release string and, on uncompressed images or extracted `vmlinux`, the `ReSukiSU-x86_64-KPM-loader/0.21` marker.

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

The released binary in [`wsa-x86_64-kpm-v0.21`](https://github.com/Ognisty321/WSA-Linux-Kernel/releases/tag/wsa-x86_64-kpm-v0.21) has SHA256 `037b9507707bffca33c56cc421b5ff7085f8ec8b8f3d2abedb93072bdadfae46`. It corresponds to WSA kernel commit `84a389e01` and ReSukiSU submodule commit `a0d26e23`.

The latest local upstream-sync candidate was built from ReSukiSU submodule `636c3315876d`, which merges ReSukiSU upstream `74b9b48b`. The reproducible build script produced kernel build `#37` with SHA256 `08112c906f8ef5655005e3589edbb9d5e088f48159e806054f9ebbd55c6814d1`; `scripts/wsa-verify-release-manifest.sh`, live WSA KPM preflight and `scripts/wsa-kpm-boot-smoke.sh` passed on the local `D:\WSA` install.

For a local release candidate, generate a manifest immediately after copying the exact kernel binary that will be shipped:

```bash
scripts/wsa-release-manifest.sh /path/to/kernel_resukisu_susfs_kpm_x86_64_5.15.104 \
  > /path/to/kernel_resukisu_susfs_kpm_x86_64_5.15.104.manifest
```

Keep that manifest next to the binary. If the tree is dirty or the artifact SHA does not match the release notes, do not publish it as a known-good release.

The manifest records the kernel artifact SHA256, kernel commit, submodule commit, KPM loader ABI, release `ksud` SHA256 when present, the Manager x86_64 packaging guard hash, the KPM module checker hash, the KPM ELF fuzz smoke harness hashes and the WSA manifest/runtime checker hashes.

Verify the manifest against the artifact and current checkout before publishing:

```bash
scripts/wsa-verify-release-manifest.sh \
  /path/to/kernel_resukisu_susfs_kpm_x86_64_5.15.104.manifest \
  /path/to/kernel_resukisu_susfs_kpm_x86_64_5.15.104
```

The verifier checks the artifact SHA256, WSA commit, KernelSU submodule commit and recorded helper script hashes. Use `SKIP_SOURCE=1` only when checking a downloaded artifact outside a matching source checkout.

## Continuous Integration

Every push to `main`, every tag and every pull request runs the [Build kernel](../../actions/workflows/build.yml) workflow on a GitHub Actions Ubuntu 22.04 runner. The workflow:

1. Sets up Clang + LLD with ccache.
2. Applies the same config and toggles documented above.
3. Builds `bzImage`.
4. Uploads the resulting kernel as a workflow artifact (14 day retention) named `wsa-kernel-x86_64-<run_number>`.

The kernel artifact downloaded from a CI run can be installed exactly the same way as the release binary documented in [INSTALL.md](INSTALL.md). The CI build tag and SHA256 are surfaced in the workflow summary.
