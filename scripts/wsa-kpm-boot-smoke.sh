#!/usr/bin/env bash
set -euo pipefail

ADB="${ADB:-adb}"
ADB_TARGET="${ADB_TARGET:-127.0.0.1:58526}"
KSUD="${KSUD:-/data/adb/ksud}"
REMOTE_DIR="${REMOTE_DIR:-/data/adb/kpm}"
KPM_NAME="${KPM_NAME:-control_kpm}"
KPM="${KPM:-$REMOTE_DIR/$KPM_NAME.kpm}"
LOCAL_KPM="${LOCAL_KPM:-KernelSU/examples/kpm-x86_64/out/$KPM_NAME.kpm}"
CONTROL_ARGS="${CONTROL_ARGS:-ping}"
LOOPS="${LOOPS:-5}"
DMESG_SCAN="${DMESG_SCAN:-1}"

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_FILES=()

log() {
	printf '[wsa-kpm-smoke] %s\n' "$*"
}

cleanup_all() {
	if [ "${#TMP_FILES[@]}" -gt 0 ]; then
		rm -f "${TMP_FILES[@]}"
	fi
	adb_su "$KSUD kpm unload '$KPM_NAME'" >/dev/null 2>&1 || true
	adb_su "rm -f '$KPM'" >/dev/null 2>&1 || true
}

adb_shell() {
	"$ADB" -s "$ADB_TARGET" shell "$@"
}

adb_su() {
	adb_shell "su -M -c \"$*\""
}

push_kpm() {
	local local_file="$1"
	local tmp_file="/data/local/tmp/$KPM_NAME.kpm"

	if [ ! -f "$local_file" ]; then
		printf 'local KPM not found: %s\n' "$local_file" >&2
		exit 1
	fi

	adb_su "mkdir -p '$REMOTE_DIR' && chmod 700 '$REMOTE_DIR'"
	"$ADB" -s "$ADB_TARGET" push "$local_file" "$tmp_file" >/dev/null
	adb_su "cp '$tmp_file' '$KPM' && chmod 600 '$KPM'"
}

log "connecting to $ADB_TARGET"
"$ADB" connect "$ADB_TARGET" >/dev/null || true
"$ADB" -s "$ADB_TARGET" wait-for-device

log "kernel"
adb_shell uname -a

log "kpm doctor"
adb_su "$KSUD kpm doctor --json"
adb_su "$KSUD kpm unload '$KPM_NAME'" >/dev/null 2>&1 || true
trap cleanup_all EXIT
DMESG_START_LINE="$(adb_su "dmesg | wc -l" | tr -dc '0-9')"
push_kpm "$ROOT/$LOCAL_KPM"

for i in $(seq 1 "$LOOPS"); do
	log "loop $i/$LOOPS: load"
	adb_su "$KSUD kpm load '$KPM'"

	log "loop $i/$LOOPS: info"
	adb_su "$KSUD kpm info '$KPM_NAME'"

	log "loop $i/$LOOPS: control"
	if adb_su "$KSUD kpm control '$KPM_NAME' '$CONTROL_ARGS'"; then
		:
	else
		log "control failed; continuing to unload for cleanup"
	fi

	log "loop $i/$LOOPS: audit"
	adb_su "$KSUD kpm audit --json"

	log "loop $i/$LOOPS: unload"
	adb_su "$KSUD kpm unload '$KPM_NAME'"
done

log "final module count"
final_num="$(adb_su "$KSUD kpm num" | tr -dc '0-9')"
printf '%s\n' "$final_num"
if [ "$final_num" != "0" ]; then
	log "expected zero loaded KPM modules, got $final_num"
	exit 1
fi

if [ "$DMESG_SCAN" = "1" ]; then
	log "dmesg scan"
	tmp="$(mktemp)"
	TMP_FILES+=("$tmp")
	adb_su "dmesg" | tail -n +"$((DMESG_START_LINE + 1))" >"$tmp"
	if grep -Eai 'BUG:|WARNING:|Oops|general protection fault|invalid opcode|KASAN|KCSAN|KFENCE|DEBUG_WX|W\+X|W\^X|writable.*executable|text_poke.*(fail|warn|bug|oops|invalid|error)|lockdep|use-after-free' "$tmp"; then
		log "kernel log contains a failure marker"
		exit 1
	fi
fi

log "pass"
