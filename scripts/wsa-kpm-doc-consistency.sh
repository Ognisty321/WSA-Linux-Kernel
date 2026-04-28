#!/usr/bin/env bash
set -euo pipefail

ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"

fail() {
	printf 'doc consistency error: %s\n' "$*" >&2
	exit 1
}

require_file() {
	local path="$1"

	[ -f "$ROOT/$path" ] || fail "missing $path"
}

require_contains() {
	local path="$1"
	local pattern="$2"

	grep -Fq -- "$pattern" "$ROOT/$path" || fail "$path is missing: $pattern"
}

require_not_contains() {
	local path="$1"
	local pattern="$2"

	if grep -Fq -- "$pattern" "$ROOT/$path"; then
		fail "$path still contains stale text: $pattern"
	fi
}

require_file docs/KPM_PORT.md
require_file docs/KPM_MODULE_COMPATIBILITY.md
require_file docs/RELEASE_GATE.md
require_file CHANGELOG.md

if [ -f "$ROOT/KernelSU/docs/KPM_X86_64_ABI.md" ]; then
	require_contains KernelSU/docs/KPM_X86_64_ABI.md 'R_X86_64_PC64'
	require_contains KernelSU/docs/KPM_X86_64_ABI.md 'Load calls `init(args, "load-file", reserved)`.'
fi
if [ -f "$ROOT/KernelSU/docs/WSA_X86_64_KPM.md" ]; then
	require_contains KernelSU/docs/WSA_X86_64_KPM.md 'R_X86_64_PC64'
	require_contains KernelSU/docs/WSA_X86_64_KPM.md 'load   -> kpm_init(args, "load-file", reserved)'
	require_not_contains KernelSU/docs/WSA_X86_64_KPM.md 'load   -> kpm_init(args, "load", reserved)'
fi

require_contains docs/KPM_PORT.md 'R_X86_64_PC64'
require_contains docs/KPM_PORT.md 'load -> kpm_init(args, "load-file", reserved)'
require_not_contains docs/KPM_PORT.md 'load -> kpm_init(args, "load", reserved)'

require_contains docs/KPM_MODULE_COMPATIBILITY.md '`blocked-abi`'
require_contains docs/KPM_MODULE_COMPATIBILITY.md 'Compat syscall hook modules'
require_contains docs/KPM_MODULE_COMPATIBILITY.md 'Compat syscall wrapper calls return `EOPNOTSUPP`.'

require_contains docs/RELEASE_GATE.md 'Kernel artifact'
require_contains docs/RELEASE_GATE.md 'Manager artifact'
require_contains docs/RELEASE_GATE.md 'ksud kpm doctor --json'
require_contains docs/RELEASE_GATE.md 'ksud kpm audit --json'
require_contains docs/RELEASE_GATE.md 'Do not publish a release as known-good'

require_contains CHANGELOG.md 'R_X86_64_PC64'
require_contains CHANGELOG.md 'load-file'

printf 'KPM documentation consistency ok\n'
