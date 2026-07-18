#!/usr/bin/env bash
set -euo pipefail

REPO="${1:-KernelSU}"
MINIMUM_VERSION="${MINIMUM_RESUKISU_VERSION:-35002}"

if ! git -C "$REPO" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
	printf 'ReSukiSU repository not found: %s\n' "$REPO" >&2
	exit 1
fi

if [ "$(git -C "$REPO" rev-parse --is-shallow-repository)" = "true" ]; then
	printf 'shallow ReSukiSU history cannot produce a valid version code: %s\n' "$REPO" >&2
	printf 'fetch the complete history before building\n' >&2
	exit 1
fi

COMMIT_COUNT="$(git -C "$REPO" rev-list --count HEAD)"
case "$COMMIT_COUNT" in
	''|*[!0-9]*)
		printf 'invalid ReSukiSU commit count: %s\n' "$COMMIT_COUNT" >&2
		exit 1
		;;
esac

VERSION_CODE=$((30000 + COMMIT_COUNT + 700))
if [ "$VERSION_CODE" -lt "$MINIMUM_VERSION" ]; then
	printf 'ReSukiSU version %s is below the supported minimum %s\n' \
		"$VERSION_CODE" "$MINIMUM_VERSION" >&2
	exit 1
fi

printf '%s\n' "$VERSION_CODE"
