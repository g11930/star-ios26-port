#!/bin/bash
# s13: checkpoint=1 -- does the kernel reach its first line of C at all?
# A checkpoint return is orderly, so the loader writes the composed log to the
# logdump partition, which we read from Android afterwards. No USB race needed.
export MSYS_NO_PATHCONV=1
F=fastboot.exe
A=adb.exe
DIR=/c/ios26
LOG=$DIR/s13-run.log
: > "$LOG"
say() { echo "[$(date +%H:%M:%S)] $*" >> "$LOG"; }

say "=== s13: checkpoint=1 (arm_vm_init entry) ==="
prod=$(timeout 10 "$F" getvar product 2>&1 | tr -d '\r' | grep -i product | head -1)
if [ -z "$prod" ]; then
	timeout 60 "$A" reboot bootloader >> "$LOG" 2>&1
	for i in $(seq 1 40); do sleep 2
		prod=$(timeout 10 "$F" getvar product 2>&1 | tr -d '\r' | grep -i product | head -1)
		[ -n "$prod" ] && break
	done
fi
[ -z "$prod" ] && { say "FATAL no fastboot"; exit 1; }
say "fastboot: $prod"
cd "$DIR" || exit 1
say "boot s13-boot.img"
timeout 150 "$F" boot s13-boot.img >> "$LOG" 2>&1
say "boot rc=$?"

for i in $(seq 1 40); do
	s=$(timeout 4 "$F" -s xnuloader getvar result 2>&1 | tr -d '\r' | grep -i "result:" | head -1)
	[ -n "$s" ] && say "[$i] $s"
	case "$s" in
		*checkpoint*|*returned*|*hung*|*exception*|*fault*)
			f=$DIR/s13-stage.bin; rm -f "$f"
			timeout 20 "$F" -s xnuloader get_staged "$f" >/dev/null 2>&1
			say "  direct grab $(stat -c %s "$f" 2>/dev/null || echo 0) bytes"
			break
			;;
	esac
	sleep 1
done

say "--- waiting for Android ---"
for i in $(seq 1 40); do
	if "$A" devices 2>/dev/null | grep -q "device$"; then say "Android at try $i"; break; fi
	sleep 3
done
sleep 4
"$A" shell "su -c 'dd if=/dev/block/sda24 bs=4096 count=3 2>/dev/null | base64'" 2>&1 | tr -d '\r\n ' | base64 -d > "$DIR/s13-logdump.bin"
say "  s13-logdump.bin $(stat -c %s "$DIR/s13-logdump.bin" 2>/dev/null || echo 0) bytes"
say DONE
tail -12 "$LOG"
