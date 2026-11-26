#!/bin/bash
# s2 = s1 + the kalloc section-offset fix.  One cold boot, one log capture.
export MSYS_NO_PATHCONV=1
A=adb.exe
F=fastboot.exe
DIR=/c/ios26
LOG=$DIR/s2-run.log
: > "$LOG"

say() { echo "[$(date +%H:%M:%S)] $*" >> "$LOG"; }

say "=== s2 boot (kalloc deltas fixed) ==="
say "adb kill-server"
"$A" kill-server >> "$LOG" 2>&1
sleep 1
say "adb reboot bootloader (will fail harmlessly if the loader is already in fastboot)"
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
say "fastboot boot s2-boot.img"
timeout 150 "$F" boot s2-boot.img >> "$LOG" 2>&1
say "boot command returned (rc=$?)"

got=0
for i in $(seq 1 40); do
	sleep 10
	res=$(timeout 10 "$F" -s xnuloader getvar result 2>&1 | tr -d '\r' | grep -i "result:" | head -1)
	if [ -n "$res" ]; then
		if [ $((i % 3)) -eq 0 ]; then say "[$i] $res"; fi
		case "$res" in
			*returned*|*hung-held*)
				rm -f s2-staged.bin
				timeout 180 "$F" -s xnuloader get_staged s2-staged.bin >> "$LOG" 2>&1
				if [ -s s2-staged.bin ]; then
					say "[$i] staged $(stat -c %s s2-staged.bin) bytes"
					got=1
					break
				fi
				;;
			*running*)
				: ;;
		esac
	else
		if [ $((i % 3)) -eq 0 ]; then say "[$i] no loader answer yet"; fi
	fi
done

if [ "$got" -ne 1 ]; then
	say "no get_staged; last resort: oem log then get_staged"
	timeout 30 "$F" -s xnuloader oem log >> "$LOG" 2>&1
	rm -f s2-staged.bin
	timeout 180 "$F" -s xnuloader get_staged s2-staged.bin >> "$LOG" 2>&1
	[ -s s2-staged.bin ] && got=2
fi

say "DONE got=$got"
tail -35 "$LOG"
