#!/bin/bash
# Fallback log capture for s2: after a long-running kernel hands back and the
# loader's USB is dead, the phone returns to Android by itself.  The loader
# flushes its log (including the kernel's live log) to /dev/block/sda24.
# Read it through `dd | base64` -- NEVER adb exec-out, it corrupts binary data.
export MSYS_NO_PATHCONV=1
A=adb.exe
DIR=/c/ios26
LOG=$DIR/s2-logdump-run.log
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
	> "$DIR/s2-logdump.b64" 2>> "$LOG"
tr -d '\r\n ' < "$DIR/s2-logdump.b64" | base64 -d > "$DIR/s2-logdump.bin" 2>> "$LOG"
say "s2-logdump.bin $(stat -c %s "$DIR/s2-logdump.bin") bytes"
tail -10 "$LOG"
