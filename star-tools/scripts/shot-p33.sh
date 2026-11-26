#!/bin/bash
# Wait for the running kernel to come back, then take the frame it left on the panel.
set -u
export MSYS_NO_PATHCONV=1
F=/d/桌面/adb-fastboot/fastboot.exe
cd /c/ios26 || exit 1
LOG=/c/ios26/shot.log
: > "$LOG"
say() { echo "[$(date +%H:%M:%S)] $*" >> "$LOG"; }

say "waiting for the loader"
for i in $(seq 1 120); do
	if timeout 8 "$F" getvar product 2>/dev/null | grep -q "xnuloader"; then
		say "loader is back (attempt $i)"
		break
	fi
	sleep 5
done
say "result: $(timeout 20 "$F" getvar result 2>&1 | head -1)"

timeout 60 "$F" oem screenshot >> "$LOG" 2>&1
say "screenshot asked for"
rm -f frame-p33.raw
if timeout 180 "$F" get_staged frame-p33.raw >> "$LOG" 2>&1; then
	say "frame: $(stat -c %s frame-p33.raw 2>/dev/null) bytes"
fi
say DONE
