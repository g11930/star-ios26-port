#!/bin/bash
# s4 = s3 + stage-5 loader gate.  Single variable: the loader now masks
# firmware IRQ handlers before XNU re-programs the GIC, so fastboot should
# stay alive WHILE the kernel runs.
#
# Capture plan (all over USB, no camera needed):
#   oem log        -> compose_live_log()  -> get_staged s4-klog-N.bin
#   oem screenshot -> stage 0xEA600000   -> get_staged s4-screen.bin
#   oem stop       -> kernel returns     -> get_staged s4-final.bin
#
# Rules: adb kill-server first; getvar product is the readiness probe;
# never abort a get_staged mid-transfer (it wedges USB); after the kernel has
# RETURNED, do NOT send `oem log` (compose_logs(NULL,0) overwrites the log).
export MSYS_NO_PATHCONV=1
A=adb.exe
F=fastboot.exe
DIR=/c/ios26
LOG=$DIR/s4-run.log
FB="$F -s xnuloader"
: > "$LOG"

say() { echo "[$(date +%H:%M:%S)] $*" >> "$LOG"; }
cap() { # cap <tag> <command...>
	local tag=$1; shift
	say "CMD: $*"
	timeout 60 "$F" -s xnuloader "$@" >> "$LOG" 2>&1
	say "  rc=$?"
}

say "=== s4: star loader USB gate + live kernel log/screenshot ==="
"$A" kill-server >> "$LOG" 2>&1
sleep 1
timeout 60 "$A" reboot bootloader >> "$LOG" 2>&1

up=0
for i in $(seq 1 60); do
	prod=$(timeout 10 "$F" getvar product 2>&1 | tr -d '\r' | grep -i "product:" | head -1)
	if [ -n "$prod" ]; then
		say "fastboot up at try $i: $prod"
		up=1
		break
	fi
	sleep 2
done
if [ "$up" -ne 1 ]; then
	say "FATAL: fastboot never answered; aborting without flashing"
	exit 1
fi

cd "$DIR" || exit 1
say "fastboot boot s4-boot.img"
timeout 150 "$F" boot s4-boot.img >> "$LOG" 2>&1
say "boot command returned (rc=$?)"

# 1. Wait for the loader to answer while a kernel is alive.  This is THE test.
usb_alive=0
for i in $(seq 1 40); do
	sleep 3
	res=$(timeout 8 "$F" -s xnuloader getvar result 2>&1 | tr -d '\r' | grep -i "result:" | head -1)
	if [ -n "$res" ]; then
		say "[$i] USB ALIVE: $res"
		usb_alive=1
		break
	fi
	if [ $((i % 5)) -eq 0 ]; then say "[$i] no loader answer"; fi
	if "$A" devices 2>/dev/null | grep -q "device$"; then
		say "[$i] Android is back before any loader answer"
		break
	fi
done
say "USB_ALIVE=$usb_alive"

if [ "$usb_alive" -eq 1 ]; then
	say "--- live capture #1 (kernel log) ---"
	cap k1 oem log
	rm -f s4-klog-1.bin
	timeout 240 "$F" -s xnuloader get_staged s4-klog-1.bin >> "$LOG" 2>&1
	say "  s4-klog-1.bin $(stat -c %s s4-klog-1.bin 2>/dev/null || echo 0) bytes"

	sleep 4
	say "--- live capture #2 (kernel log, a few seconds later) ---"
	cap k2 oem log
	rm -f s4-klog-2.bin
	timeout 240 "$F" -s xnuloader get_staged s4-klog-2.bin >> "$LOG" 2>&1
	say "  s4-klog-2.bin $(stat -c %s s4-klog-2.bin 2>/dev/null || echo 0) bytes"

	say "--- screenshot (raw framebuffer 0xEA600000) ---"
	geom=$(timeout 10 "$F" -s xnuloader getvar screen 2>&1 | tr -d '\r' | grep -i "screen:" | head -1)
	say "  geometry: $geom"
	cap shot oem screenshot
	rm -f s4-screen.bin
	timeout 300 "$F" -s xnuloader get_staged s4-screen.bin >> "$LOG" 2>&1
	say "  s4-screen.bin $(stat -c %s s4-screen.bin 2>/dev/null || echo 0) bytes"

	say "--- ask the kernel to return ---"
	cap stop oem stop
	for i in $(seq 1 30); do
		sleep 4
		res=$(timeout 8 "$F" -s xnuloader getvar result 2>&1 | tr -d '\r' | grep -i "result:" | head -1)
		[ -n "$res" ] && say "[$i] $res"
		case "$res" in
			*returned*|*hung-held*) break ;;
		esac
		if "$A" devices 2>/dev/null | grep -q "device$"; then
			say "[$i] Android is back"
			break
		fi
	done
	# Returned: go STRAIGHT to get_staged, never `oem log` here.
	rm -f s4-final.bin
	timeout 240 "$F" -s xnuloader get_staged s4-final.bin >> "$LOG" 2>&1
	say "  s4-final.bin $(stat -c %s s4-final.bin 2>/dev/null || echo 0) bytes"
else
	say "USB never answered: fall back to logdump after Android returns"
	for i in $(seq 1 30); do
		if "$A" devices 2>/dev/null | grep -q "device$"; then
			say "Android is back at try $i"
			break
		fi
		sleep 5
	done
fi

say "DONE"
tail -60 "$LOG"
