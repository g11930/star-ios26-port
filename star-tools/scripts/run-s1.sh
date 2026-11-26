#!/bin/bash
# First real flash of star-native (s1).  One cold boot, one log capture.
# Host-side only; the phone is touched exactly once with `fastboot boot`.
#
# Rules carried over from the earlier rounds:
#   * adb kill-server FIRST, otherwise fastboot cannot see this phone.
#   * `fastboot getvar product` is the only reliable readiness probe.
#   * Image/log paths must be pure ASCII (C:\ios26).
#   * Do NOT send `oem log` after the kernel has returned: compose_logs(NULL,0)
#     overwrites the kernel log.  Wait for `getvar result: returned` and go
#     straight to `get_staged`.
#   * Never abort a get_staged in the middle: it wedges the loader's USB.
export MSYS_NO_PATHCONV=1
A=adb.exe
F=fastboot.exe
DIR=/c/ios26
LOG=$DIR/s1-run.log
: > "$LOG"

say() { echo "[$(date +%H:%M:%S)] $*" >> "$LOG"; }

say "=== s1 baseline boot ==="
say "adb kill-server"
"$A" kill-server >> "$LOG" 2>&1
sleep 1

say "adb reboot bootloader"
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
say "fastboot boot s1-boot.img"
timeout 150 "$F" boot s1-boot.img >> "$LOG" 2>&1
say "boot command returned (rc=$?)"

got=0
for i in $(seq 1 36); do
	sleep 10
	res=$(timeout 10 "$F" -s xnuloader getvar result 2>&1 | tr -d '\r' | grep -i "result:" | head -1)
	if [ -n "$res" ]; then
		say "[$i] $res"
		case "$res" in
			*returned*)
				rm -f s1-staged.bin
				timeout 180 "$F" -s xnuloader get_staged s1-staged.bin >> "$LOG" 2>&1
				if [ -s s1-staged.bin ]; then
					say "[$i] staged $(stat -c %s s1-staged.bin) bytes"
					got=1
					break
				fi
				;;
			*running*)
				: ;;   # kernel still owns the CPU; loader_return_after=120 will end it
		esac
	else
		if [ $((i % 3)) -eq 0 ]; then say "[$i] no loader answer yet"; fi
	fi
	if timeout 10 "$A" devices 2>/dev/null | grep -q "device$"; then
		say "[$i] Android is back (kernel returned early or rebooted)"
	fi
done

if [ "$got" -ne 1 ]; then
	say "get_staged not obtained; last resort: oem log then get_staged"
	timeout 30 "$F" -s xnuloader oem log >> "$LOG" 2>&1
	rm -f s1-staged.bin
	timeout 180 "$F" -s xnuloader get_staged s1-staged.bin >> "$LOG" 2>&1
	[ -s s1-staged.bin ] && got=2
fi

say "DONE got=$got"
tail -30 "$LOG"
