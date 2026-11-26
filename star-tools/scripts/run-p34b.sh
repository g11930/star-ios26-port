#!/bin/bash
# P34 already staged into the loader; this runs it and takes the log back.
# The loader runs a stage'd payload on its own, so the phone does not have to go round through
# Android to boot a new kernel: stage, oem run, getvar result, get_staged.
set -u
export MSYS_NO_PATHCONV=1
F=/d/桌面/adb-fastboot/fastboot.exe
OUT=/c/ios26
LOG=$OUT/p34b-run.log
: > "$LOG"
say() { echo "[$(date +%H:%M:%S)] $*" >> "$LOG"; }

say "oem run"
timeout 60 "$F" oem run >> "$LOG" 2>&1
say "oem run returned"

# the kernel holds the machine for loader_return_after seconds; getvar result waits it out
say "waiting for the kernel to come back"
timeout 700 "$F" getvar result >> "$LOG" 2>&1
say "getvar done"

for i in 1 2 3 4 5 6; do
	if timeout 240 "$F" get_staged "$OUT/p34-staged.bin" >> "$LOG" 2>&1; then
		if [ -s "$OUT/p34-staged.bin" ]; then
			say "staged: $(stat -c %s "$OUT/p34-staged.bin") bytes"
			break
		fi
	fi
	say "stage attempt $i came back empty"
	sleep 5
done
say DONE
