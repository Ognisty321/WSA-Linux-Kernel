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
if [ "$(git -C KernelSU rev-parse --is-shallow-repository)" = "true" ]; then
  git -C KernelSU fetch --unshallow --tags origin
fi
scripts/wsa-resukisu-version.sh KernelSU
```

## Configure the Kernel

Start from the WSA x64 config and enable the ReSukiSU, SUSFS and KPM options used by CI:

```bash
cp configs/wsa/config-wsa-x64 .config

./scripts/config --file .config --set-str LOCALVERSION '-WSA-ReSukiSU'
./scripts/config --file .config --set-str KSU_FULL_NAME_FORMAT \
  '%TAG_NAME%-%COMMIT_SHA%@%REPO_NAME%-%KSU_VERSION%'

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

resukisu_version="$(scripts/wsa-resukisu-version.sh KernelSU)"
strings KernelSU/kernel/supercall/dispatch.o | grep -F -- "-$resukisu_version"
```

The kernel image is at:

```text
arch/x86/boot/bzImage
```

## Verify

```bash
strings arch/x86/boot/bzImage | grep -E 'WSA-ReSukiSU|KPM-loader' | head
```

You should see the `5.15.104-...-WSA-ReSukiSU` release string (an untagged dirty tree may append `+`) and, on uncompressed images or extracted `vmlinux`, the `ReSukiSU-x86_64-KPM-loader/0.21` marker.

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

The released binary in [`wsa-x86_64-kpm-v0.23`](https://github.com/Ognisty321/WSA-Linux-Kernel/releases/tag/wsa-x86_64-kpm-v0.23) has SHA256 `1bb844874f3b4e88b91f89b4673c257119f4063d9e6207aa5ac5be1c5a1305cd`. It corresponds to WSA kernel commit `329edcc7d9c6cd671b96ec2570632839a4526f30` and ReSukiSU submodule commit `092354e5eb274a07b535c79973f695f756ec2c33`.

The `v0.23` tag build pins ReSukiSU `092354e5eb27` and SUSFS `v2.2.0`. GitHub build `#23`, the release manifest verifier and the paired Manager/`ksud` x86_64 packaging guards passed. Live boot validation of the exact tagged artifact remains pending; the earlier local loader `0.21` validation is the runtime baseline.

For a local release candidate, generate a manifest immediately after copying the exact kernel binary that will be shipped:

```bash
scripts/wsa-release-manifest.sh /path/to/kernel_resukisu_susfs_kpm_x86_64_5.15.104 \
  > /path/to/kernel_resukisu_susfs_kpm_x86_64_5.15.104.manifest
```

Keep that manifest next to the binary. If the tree is dirty or the artifact SHA does not match the release notes, do not publish it as a known-good release.

The manifest records the kernel artifact SHA256, kernel commit, submodule commit, ReSukiSU shallow state, commit count and version code, KPM loader ABI, release `ksud` SHA256 when present, the Manager x86_64 packaging guard hash, the KPM module checker hash, the KPM ELF fuzz smoke harness hashes and the WSA manifest/runtime checker hashes.

Verify the manifest against the artifact and current checkout before publishing:

```bash
scripts/wsa-verify-release-manifest.sh \
  /path/to/kernel_resukisu_susfs_kpm_x86_64_5.15.104.manifest \
  /path/to/kernel_resukisu_susfs_kpm_x86_64_5.15.104
```

The verifier checks the artifact SHA256, WSA commit, KernelSU submodule commit and recorded helper script hashes. Use `SKIP_SOURCE=1` only when checking a downloaded artifact outside a matching source checkout.

Before publishing a release, complete the evidence checklist in [RELEASE_GATE.md](RELEASE_GATE.md). A release should not be described as known-good unless the kernel artifact, Manager artifact, Android x86_64 `ksud` or `libksud.so`, loader marker, WSA package and live diagnostics all refer to the same validated state.

## Continuous Integration

Every push to `main`, every tag and every pull request runs the [Build kernel](../../actions/workflows/build.yml) workflow on a GitHub Actions Ubuntu 22.04 runner. The workflow:

1. Sets up Clang + LLD with ccache.
2. Applies the same config and toggles documented above.
3. Builds `bzImage`.
4. Uploads the resulting kernel as a workflow artifact (14 day retention) named `wsa-kernel-x86_64-<run_number>`.

The kernel artifact downloaded from a CI run can be installed exactly the same way as the release binary documented in [INSTALL.md](INSTALL.md). The CI build tag and SHA256 are surfaced in the workflow summary.

Documentation-only changes run the `Documentation checks` workflow. It validates ABI-sensitive text such as the supported x86_64 relocation list, the `load-file` lifecycle event and release gate requirements without starting a full kernel build.
