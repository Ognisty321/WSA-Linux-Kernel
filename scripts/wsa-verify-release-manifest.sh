#!/usr/bin/env bash
set -euo pipefail

usage() {
	cat >&2 <<'USAGE'
Usage: scripts/wsa-verify-release-manifest.sh BUILD_INFO.txt [artifact]

Checks that a WSA release manifest matches the kernel artifact, current source
checkout, KernelSU submodule and recorded helper script hashes.

Set SKIP_SOURCE=1 to verify only artifact and recorded file hashes.
USAGE
}

if [ "$#" -lt 1 ] || [ "$#" -gt 2 ]; then
	usage
	exit 2
fi

MANIFEST="$1"
ARTIFACT_OVERRIDE="${2:-}"
SKIP_SOURCE="${SKIP_SOURCE:-0}"

if [ ! -f "$MANIFEST" ]; then
	printf 'manifest not found: %s\n' "$MANIFEST" >&2
	exit 2
fi

manifest_value() {
	local key="$1"

	awk -v key="$key" '
		index($0, key "=") == 1 {
			print substr($0, length(key) + 2)
			found = 1
			exit
		}
		END {
			exit found ? 0 : 1
		}
	' "$MANIFEST"
}

required_value() {
	local key="$1"
	local value

	if ! value="$(manifest_value "$key")"; then
		printf 'manifest missing required key: %s\n' "$key" >&2
		exit 1
	fi
	printf '%s\n' "$value"
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

resolve_path() {
	local path="$1"
	local manifest_dir

	case "$path" in
	/*)
		printf '%s\n' "$path"
		;;
	*)
		if [ -e "$path" ]; then
			printf '%s\n' "$path"
			return
		fi
		manifest_dir="$(cd -- "$(dirname -- "$MANIFEST")" && pwd)"
		printf '%s/%s\n' "$manifest_dir" "$path"
		;;
	esac
}

failures=0

check_equal() {
	local label="$1"
	local expected="$2"
	local actual="$3"

	if [ "$expected" != "$actual" ]; then
		printf '%s mismatch: expected %s, got %s\n' "$label" "$expected" "$actual" >&2
		failures=1
	else
		printf '%s ok: %s\n' "$label" "$actual"
	fi
}

check_file_hash() {
	local path_key="$1"
	local sha_key="$2"
	local path expected actual resolved

	if ! path="$(manifest_value "$path_key")"; then
		return
	fi
	if ! expected="$(manifest_value "$sha_key")"; then
		printf 'manifest has %s but is missing %s\n' "$path_key" "$sha_key" >&2
		failures=1
		return
	fi

	resolved="$(resolve_path "$path")"
	if [ ! -f "$resolved" ]; then
		printf '%s file not found: %s\n' "$path_key" "$resolved" >&2
		failures=1
		return
	fi

	actual="$(sha256sum "$resolved" | awk '{ print $1 }')"
	check_equal "$sha_key" "$expected" "$actual"
}

artifact="${ARTIFACT_OVERRIDE:-$(required_value artifact)}"
artifact="$(resolve_path "$artifact")"
expected_artifact_sha="$(required_value artifact_sha256)"

if [ ! -f "$artifact" ]; then
	printf 'artifact not found: %s\n' "$artifact" >&2
	exit 1
fi

actual_artifact_sha="$(sha256sum "$artifact" | awk '{ print $1 }')"
check_equal artifact_sha256 "$expected_artifact_sha" "$actual_artifact_sha"

if [ "$SKIP_SOURCE" != "1" ] && git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
	expected_kernel_commit="$(required_value kernel_commit)"
	actual_kernel_commit="$(git rev-parse HEAD)"
	check_equal kernel_commit "$expected_kernel_commit" "$actual_kernel_commit"

	expected_kernel_dirty="$(required_value kernel_dirty)"
	actual_kernel_dirty="$(git_tracked_dirty .)"
	check_equal kernel_dirty "$expected_kernel_dirty" "$actual_kernel_dirty"

	if git -C KernelSU rev-parse --is-inside-work-tree >/dev/null 2>&1; then
		expected_kernelsu_commit="$(required_value kernelsu_commit)"
		actual_kernelsu_commit="$(git -C KernelSU rev-parse HEAD)"
		check_equal kernelsu_commit "$expected_kernelsu_commit" "$actual_kernelsu_commit"

		expected_kernelsu_dirty="$(required_value kernelsu_dirty)"
		actual_kernelsu_dirty="$(git_tracked_dirty KernelSU)"
		check_equal kernelsu_dirty "$expected_kernelsu_dirty" "$actual_kernelsu_dirty"
	fi
fi

check_file_hash ksud_x86_64_android_release ksud_x86_64_android_release_sha256
check_file_hash manager_x86_64_check_script manager_x86_64_check_script_sha256
check_file_hash kpm_x86_64_module_check_script kpm_x86_64_module_check_script_sha256
check_file_hash kpm_x86_64_fuzz_smoke_script kpm_x86_64_fuzz_smoke_script_sha256
check_file_hash kpm_x86_64_fuzz_harness kpm_x86_64_fuzz_harness_sha256
check_file_hash wsa_manifest_verify_script wsa_manifest_verify_script_sha256
check_file_hash wsa_runtime_ksud_check_script wsa_runtime_ksud_check_script_sha256

if [ "$failures" -ne 0 ]; then
	exit 1
fi

echo "release manifest ok: $MANIFEST"
