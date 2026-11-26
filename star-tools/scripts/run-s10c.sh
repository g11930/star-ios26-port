#!/bin/bash
# s10c: flash the current (stage-9) kernel, let it fail, come back to Android, and
# read the loader's own logdump partition (sda24) -- the one channel that does not
# race the USB endpoint.  On the s7 image this partition held the loader log *and*
# "== KERNEL LOG ==" with the full panic, because the loader composes and writes it
# when the kernel comes back.
export MSYS_NO_PATHCONV=1
F=fastboot.exe
A=adb.exe
DIR=/c/ios26
LOG=$DIR/s10c-run.log
: > "$LOG"
say() { echo "[$(date +%H:%M:%S)] $*" >> "$LOG"; }

say "=== s10c: flash stage-9 kernel, then read logdump from Android ==="
prod=$(timeout 10 "$F" getvar product 2>&1 | tr -d '\r' | grep -i "product:" | head -1)
if [ -z "$prod" ]; then
	timeout 60 "$A" reboot bootloader >> "$LOG" 2>&1
	for i in $(seq 1 40); do
		sleep 2
		prod=$(timeout 10 "$F" getvar product 2>&1 | tr -d '\r' | grep -i "product:" | head -1)
		[ -n "$prod" ] && break
	done
fi
[ -z "$prod" ] && { say "FATAL: no fastboot"; exit 1; }
say "fastboot: $prod"

cd "$DIR" || exit 1
say "boot s10-boot.img"
timeout 150 "$F" boot s10-boot.img >> "$LOG" 2>&1
say "boot returned rc=$?"

# opportunistic: any non-idle answer before the endpoint dies is free evidence
for i in $(seq 1 60); do
	s=$(timeout 5 "$F" -s xnuloader getvar result 2>&1 | tr -d '\r' | grep -i "result:" | head -1)
	if [ -n "$s" ]; then
		say "[$i] $s"
		case "$s" in *idle*) : ;; *)
			f=/c/ios26/s10c-live.bin; rm -f "$f"
			timeout 20 "$F" -s xnuloader get_staged "$f" >/dev/null 2>&1
			say "  live grab $(stat -c %s "$f" 2>/dev/null || echo 0) bytes"
			;;
		esac
	fi
	sleep 1
done

say "--- waiting for Android ---"
got=0
for i in $(seq 1 60); do
	if "$A" devices 2>/dev/null | grep -q "device$"; then say "Android at try $i"; got=1; break; fi
	sleep 3
done
if [ "$got" -ne 1 ]; then say "Android never came back"; tail -20 "$LOG"; exit 1; fi

sleep 5
say "--- reading logdump (sda24) ---"
"$A" shell "su -c 'dd if=/dev/block/sda24 bs=4096 count=3 2>/dev/null | base64'" 2>&1 | tr -d '\r\n ' | base64 -d > "$DIR/s10c-logdump.bin"
say "  s10c-logdump.bin $(stat -c %s "$DIR/s10c-logdump.bin" 2>/dev/null || echo 0) bytes"
say "DONE"
tail -15 "$LOG"
