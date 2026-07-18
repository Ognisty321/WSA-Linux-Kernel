#!/usr/bin/env bash
set -euo pipefail

ARTIFACT="${1:-arch/x86/boot/bzImage}"

if [ ! -f "$ARTIFACT" ]; then
	printf 'artifact not found: %s\n' "$ARTIFACT" >&2
	exit 1
fi

kv() {
	printf '%s=%s\n' "$1" "$2"
}

git_tracked_dirty() {
	local repo="${1:-.}"

	git -C "$repo" update-index -q --refresh 2>/dev/null || true
	if ! git -C "$repo" diff --quiet --ignore-submodules=dirty -- 2>/dev/null ||
		! git -C "$repo" diff --cached --quiet --ignore-submodules=dirty -- 2>/dev/null; then
		printf true
	else
		printf false
	fi
}

kv artifact "$ARTIFACT"
kv artifact_sha256 "$(sha256sum "$ARTIFACT" | awk '{print $1}')"
kv generated_utc "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
kv kernel_repo "$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
kv kernel_commit "$(git rev-parse HEAD 2>/dev/null || printf unknown)"
kv kernel_branch "$(git rev-parse --abbrev-ref HEAD 2>/dev/null || printf unknown)"
kv kernel_tag "$(git describe --tags --exact-match 2>/dev/null || printf untagged)"
kv kernel_dirty "$(git_tracked_dirty .)"

if command -v powershell.exe >/dev/null 2>&1; then
	powershell.exe -NoProfile -NonInteractive -Command '
$ci = Get-ComputerInfo
"windows_product=$($ci.WindowsProductName)"
"windows_version=$($ci.WindowsVersion)"
"windows_build=$($ci.OsBuildNumber)"
$hvci = Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity" -ErrorAction SilentlyContinue
if ($hvci) { "windows_hvci_enabled=$($hvci.Enabled)" }
$wsa = Get-AppxPackage -Name "MicrosoftCorporationII.WindowsSubsystemForAndroid" -ErrorAction SilentlyContinue
if ($wsa) {
  "wsa_package_full_name=$($wsa.PackageFullName)"
  "wsa_package_version=$($wsa.Version)"
  "wsa_install_location=$($wsa.InstallLocation)"
}
' | tr -d '\r'
fi

if git -C KernelSU rev-parse --is-inside-work-tree >/dev/null 2>&1; then
	kv kernelsu_commit "$(git -C KernelSU rev-parse HEAD 2>/dev/null || printf unknown)"
	kv kernelsu_branch "$(git -C KernelSU rev-parse --abbrev-ref HEAD 2>/dev/null || printf unknown)"
	kv kernelsu_dirty "$(git_tracked_dirty KernelSU)"
	if [ -f KernelSU/kernel/kpm/kpm_loader_x86_64.h ]; then
		loader_name="$(sed -n 's/^#define SUKISU_KPM_LOADER_NAME "\(.*\)"/\1/p' KernelSU/kernel/kpm/kpm_loader_x86_64.h)"
		loader_semver="$(sed -n 's/^#define SUKISU_KPM_LOADER_SEMVER "\(.*\)"/\1/p' KernelSU/kernel/kpm/kpm_loader_x86_64.h)"
		loader_abi="$(sed -n 's/^#define SUKISU_KPM_X86_64_ABI_VERSION \([0-9][0-9]*\)$/\1/p' KernelSU/kernel/kpm/kpm_loader_x86_64.h)"
		if [ -n "$loader_name" ] && [ -n "$loader_semver" ]; then
			kv kpm_loader "$loader_name/$loader_semver"
		fi
		if [ -n "$loader_abi" ]; then
			kv kpm_x86_64_abi "$loader_abi"
		fi
	fi
	if [ -f KernelSU/userspace/ksud/target/x86_64-linux-android/release/ksud ]; then
		kv ksud_x86_64_android_release "KernelSU/userspace/ksud/target/x86_64-linux-android/release/ksud"
		kv ksud_x86_64_android_release_sha256 \
			"$(sha256sum KernelSU/userspace/ksud/target/x86_64-linux-android/release/ksud | awk '{print $1}')"
	fi
	if [ -f KernelSU/scripts/check-manager-kpm-x86.sh ]; then
		kv manager_x86_64_check_script "KernelSU/scripts/check-manager-kpm-x86.sh"
		kv manager_x86_64_check_script_sha256 \
			"$(sha256sum KernelSU/scripts/check-manager-kpm-x86.sh | awk '{print $1}')"
	fi
	if [ -f KernelSU/scripts/check-kpm-module-x86.sh ]; then
		kv kpm_x86_64_module_check_script "KernelSU/scripts/check-kpm-module-x86.sh"
		kv kpm_x86_64_module_check_script_sha256 \
			"$(sha256sum KernelSU/scripts/check-kpm-module-x86.sh | awk '{print $1}')"
	fi
	if [ -f KernelSU/scripts/fuzz-kpm-x86-smoke.sh ]; then
		kv kpm_x86_64_fuzz_smoke_script "KernelSU/scripts/fuzz-kpm-x86-smoke.sh"
		kv kpm_x86_64_fuzz_smoke_script_sha256 \
			"$(sha256sum KernelSU/scripts/fuzz-kpm-x86-smoke.sh | awk '{print $1}')"
	fi
	if [ -f KernelSU/tools/kpm-x86-fuzz/kpm_elf_fuzz.c ]; then
		kv kpm_x86_64_fuzz_harness "KernelSU/tools/kpm-x86-fuzz/kpm_elf_fuzz.c"
		kv kpm_x86_64_fuzz_harness_sha256 \
			"$(sha256sum KernelSU/tools/kpm-x86-fuzz/kpm_elf_fuzz.c | awk '{print $1}')"
	fi
fi

if [ -f .config ]; then
	kv kernel_release "$(make ARCH=x86_64 LLVM=1 -s kernelrelease 2>/dev/null || printf unknown)"
	printf 'config_sha256=%s\n' "$(sha256sum .config | awk '{print $1}')"
	grep -E '^CONFIG_(LOCALVERSION|KSU|KPM|KALLSYMS|DEBUG_WX|KASAN|KCSAN|KFENCE|PROVE_LOCKING)=' .config | sort
fi

if [ -f scripts/wsa-verify-release-manifest.sh ]; then
	kv wsa_manifest_verify_script "scripts/wsa-verify-release-manifest.sh"
	kv wsa_manifest_verify_script_sha256 \
		"$(sha256sum scripts/wsa-verify-release-manifest.sh | awk '{print $1}')"
fi

if [ -f scripts/wsa-check-runtime-ksud.sh ]; then
	kv wsa_runtime_ksud_check_script "scripts/wsa-check-runtime-ksud.sh"
	kv wsa_runtime_ksud_check_script_sha256 \
		"$(sha256sum scripts/wsa-check-runtime-ksud.sh | awk '{print $1}')"
fi

kv clang "$({ clang --version 2>/dev/null || true; } | sed -n '1p')"
kv ld_lld "$({ ld.lld --version 2>/dev/null || true; } | sed -n '1p')"
kv rustc "$({ rustc --version 2>/dev/null || true; } | sed -n '1p')"
kv cargo "$({ cargo --version 2>/dev/null || true; } | sed -n '1p')"
