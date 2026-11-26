#!/bin/bash
# s3 = s2 + `-v`.  The kernel text console is drawn on the panel itself, so
# the primary observation is a PHOTO of the screen while the kernel runs.
# USB/fastboot usually dies once a healthy kernel takes over; this script
# still tries get_staged, but a missing log is NOT a failure signal here.
export MSYS_NO_PATHCONV=1
A=adb.exe
F=fastboot.exe
DIR=/c/ios26
LOG=$DIR/s3-run.log
: > "$LOG"

say() { echo "[$(date +%H:%M:%S)] $*" >> "$LOG"; }

say "=== s3 boot (verbose console on the panel) ==="
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
say "fastboot boot s3-boot.img -- WATCH THE SCREEN NOW"
timeout 150 "$F" boot s3-boot.img >> "$LOG" 2>&1
say "boot command returned (rc=$?)"

got=0
for i in $(seq 1 30); do
	sleep 10
	res=$(timeout 8 "$F" -s xnuloader getvar result 2>&1 | tr -d '\r' | grep -i "result:" | head -1)
	if [ -n "$res" ]; then
		say "[$i] $res"
		case "$res" in
			*returned*|*hung-held*)
				rm -f s3-staged.bin
				timeout 180 "$F" -s xnuloader get_staged s3-staged.bin >> "$LOG" 2>&1
				if [ -s s3-staged.bin ]; then
					say "[$i] staged $(stat -c %s s3-staged.bin) bytes"
					got=1
					break
				fi
				;;
		esac
	else
		if [ $((i % 3)) -eq 0 ]; then say "[$i] no loader answer (USB owned by the kernel)"; fi
	fi
	if "$A" devices 2>/dev/null | grep -q "device$"; then
		say "[$i] Android is back"
		break
	fi
done

say "DONE got=$got (the screen photo is the primary evidence)"
tail -35 "$LOG"
