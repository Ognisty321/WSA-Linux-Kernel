#!/usr/bin/env bash
set -euo pipefail

ADB="${ADB:-adb}"
ADB_TARGET="${ADB_TARGET:-127.0.0.1:58526}"
KSUD="${KSUD:-/data/adb/ksud}"
LOCAL_KSUD="${LOCAL_KSUD:-KernelSU/userspace/ksud/target/x86_64-linux-android/release/ksud}"

log() {
	printf '[wsa-ksud-check] %s\n' "$*"
}

adb_shell() {
	"$ADB" -s "$ADB_TARGET" shell "$@"
}

adb_su() {
	adb_shell "su -M -c \"$*\""
}

log "connecting to $ADB_TARGET"
"$ADB" connect "$ADB_TARGET" >/dev/null || true
"$ADB" -s "$ADB_TARGET" wait-for-device

log "kernel"
adb_shell uname -a

if [ -f "$LOCAL_KSUD" ]; then
	log "local release ksud"
	sha256sum "$LOCAL_KSUD"
	if [ -x KernelSU/scripts/check-manager-kpm-x86.sh ]; then
		KernelSU/scripts/check-manager-kpm-x86.sh "$LOCAL_KSUD"
	fi
else
	log "local release ksud not found: $LOCAL_KSUD"
fi

log "remote ksud path: $KSUD"
if adb_su "$KSUD kpm --help" >/dev/null 2>&1; then
	log "remote ksud exposes kpm"
	adb_su "$KSUD kpm version" || true
	adb_su "$KSUD kpm doctor --json" || true
	exit 0
fi

log "remote ksud does not expose kpm"
adb_su "$KSUD --help 2>&1 | head -80" || true
exit 1
