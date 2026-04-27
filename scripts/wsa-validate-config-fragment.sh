#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
BASE_CONFIG="${BASE_CONFIG:-configs/wsa/config-wsa-x64}"
FRAGMENT="${1:-}"
BUILD="${BUILD:-0}"

if [ -z "$FRAGMENT" ]; then
	printf 'usage: %s configs/wsa/fragments/<fragment>.config\n' "$0" >&2
	exit 2
fi

cd "$ROOT"

if [ ! -f "$BASE_CONFIG" ]; then
	printf 'base config not found: %s\n' "$BASE_CONFIG" >&2
	exit 1
fi
if [ ! -f "$FRAGMENT" ]; then
	printf 'fragment not found: %s\n' "$FRAGMENT" >&2
	exit 1
fi

name="$(basename "$FRAGMENT" .config)"
OUT="${OUT:-out/wsa-validation/$name}"

log() {
	printf '[wsa-fragment] %s\n' "$*"
}

requested_symbols() {
	sed -n \
		-e 's/^\(CONFIG_[A-Za-z0-9_]*\)=.*/\1/p' \
		-e 's/^# \(CONFIG_[A-Za-z0-9_]*\) is not set$/\1/p' \
		"$FRAGMENT" | sort -u
}

log "base: $BASE_CONFIG"
log "fragment: $FRAGMENT"
log "out: $OUT"

if [ -f .config ] || [ -d include/config ] || [ -d arch/x86/include/generated ]; then
	cat >&2 <<'EOF'
The kernel source tree has in-tree build artifacts.
Out-of-tree validation config checks require a clean source tree.

Use a clean clone, or clean generated files with:

  make ARCH=x86_64 mrproper

This script did not modify the source tree.
EOF
	exit 1
fi

mkdir -p "$OUT"
scripts/kconfig/merge_config.sh -m -O "$OUT" "$BASE_CONFIG" "$FRAGMENT" | tee "$OUT/merge.log"
make O="$OUT" ARCH=x86_64 LLVM=1 olddefconfig | tee "$OUT/olddefconfig.log"

requested_symbols > "$OUT/requested-symbols.txt"
: > "$OUT/kept-symbols.txt"
: > "$OUT/dropped-symbols.txt"

while IFS= read -r sym; do
	requested="$(grep -w -e "$sym" "$FRAGMENT" || true)"
	actual="$(grep -w -e "$sym" "$OUT/.config" || true)"
	if [ -n "$actual" ] && [ "$requested" = "$actual" ]; then
		printf '%s\n' "$actual" >> "$OUT/kept-symbols.txt"
	else
		printf '%s requested=%s actual=%s\n' "$sym" "${requested:-<none>}" "${actual:-<none>}" >> "$OUT/dropped-symbols.txt"
	fi
done < "$OUT/requested-symbols.txt"

log "kept symbols: $(wc -l < "$OUT/kept-symbols.txt")"
log "dropped symbols: $(wc -l < "$OUT/dropped-symbols.txt")"

if [ -s "$OUT/dropped-symbols.txt" ]; then
	log "dropped symbol details:"
	sed -n '1,120p' "$OUT/dropped-symbols.txt"
fi

if [ "$BUILD" = "1" ]; then
	log "building validation bzImage"
	make O="$OUT" ARCH=x86_64 LLVM=1 -j"$(nproc)" bzImage
	scripts/wsa-release-manifest.sh "$OUT/arch/x86/boot/bzImage" > "$OUT/BUILD_INFO.txt"
	sha256sum "$OUT/arch/x86/boot/bzImage" > "$OUT/SHA256SUMS.txt"
	log "build info: $OUT/BUILD_INFO.txt"
fi

log "pass"
