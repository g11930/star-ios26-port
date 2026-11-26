#!/bin/bash
# s9: forced fb_dcs=0 (no K90 DPU code on star) + -v (kernel paints its own log).
#
# The evidence this run is the PANEL, not USB: s8 showed that as soon as the
# kernel is alive the fastboot endpoint dies, and every get_staged hangs.
# So this script flashes, then only asks `getvar result` once every 5 s -- no
# `oem log`, no `get_staged`, nothing that stages a transfer while the kernel
# owns the USB controller.  Photograph the screen inside the first three
# minutes (loader_return_after=200 hands control back at 200 s).
export MSYS_NO_PATHCONV=1
A=adb.exe
F=fastboot.exe
DIR=/c/ios26
LOG=$DIR/s9-run.log
: > "$LOG"

say() { echo "[$(date +%H:%M:%S)] $*" >> "$LOG"; }
q() { timeout 8 "$F" -s xnuloader "$@" 2>&1 | tr -d '\r'; }

say "=== s9: fb_dcs=0 + kernel text console ==="
"$A" kill-server >> "$LOG" 2>&1
sleep 1
for i in $(seq 1 30); do
	if "$A" devices 2>/dev/null | grep -q "device$"; then say "adb sees the phone at try $i"; break; fi
	sleep 2
done
timeout 60 "$A" reboot bootloader >> "$LOG" 2>&1
say "reboot bootloader sent (rc=$?)"

up=0
for i in $(seq 1 60); do
	prod=$(timeout 10 "$F" getvar product 2>&1 | tr -d '\r' | grep -i "product:" | head -1)
	if [ -n "$prod" ]; then say "fastboot up: $prod"; up=1; break; fi
	sleep 2
done
if [ "$up" -ne 1 ]; then say "FATAL: no fastboot"; exit 1; fi

cd "$DIR" || exit 1
say "fastboot boot s9-boot.img"
timeout 150 "$F" boot s9-boot.img >> "$LOG" 2>&1
say "boot command returned (rc=$?)"

# Light polling only.  Everything else would stage a USB transfer while the
# kernel owns the controller, which is exactly what killed s8's captures.
last=""
for i in $(seq 1 60); do
	sleep 5
	s=$(q getvar result 2>/dev/null | grep -i "result:" | head -1)
	if [ "$s" != "$last" ] && [ -n "$s" ]; then say "[$((i*5))s] $s"; last="$s"; fi
	if "$A" devices 2>/dev/null | grep -q "device$"; then say "[$((i*5))s] Android is back"; break; fi
done

say "DONE -- the screen was the evidence for this run"
tail -20 "$LOG"
