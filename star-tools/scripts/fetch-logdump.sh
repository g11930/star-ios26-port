#!/bin/bash
# Generic fallback log capture: after a kernel run returns to Android, the
# loader has flushed its log (and the kernel live log) to /dev/block/sda24.
# Read via `dd | base64` inside adb shell -- NEVER adb exec-out (corrupts data).
# Usage: fetch-logdump.sh <tag>   -> /c/ios26/<tag>-logdump.bin
export MSYS_NO_PATHCONV=1
A=adb.exe
TAG=${1:?usage: fetch-logdump.sh TAG}
DIR=/c/ios26
BIN=$DIR/$TAG-logdump.bin
LOG=$DIR/$TAG-logdump-run.log
: > "$LOG"

say() { echo "[$(date +%H:%M:%S)] $*" >> "$LOG"; }

say "waiting for Android (up to 10 min)"
up=0
for i in $(seq 1 120); do
	if "$A" devices 2>/dev/null | grep -q "device$"; then
		say "Android online at try $i"
		up=1
		break
	fi
	sleep 5
done
if [ "$up" -ne 1 ]; then
	say "FATAL: Android never came back"
	exit 1
fi

say "reading /dev/block/sda24 through base64"
"$A" shell "su -c 'dd if=/dev/block/sda24 bs=4096 count=4096 2>/dev/null | base64'" \
	> "$DIR/$TAG-logdump.b64" 2>> "$LOG"
tr -d '\r\n ' < "$DIR/$TAG-logdump.b64" | base64 -d > "$BIN" 2>> "$LOG"
say "$TAG-logdump.bin $(stat -c %s "$BIN") bytes"
tail -10 "$LOG"
