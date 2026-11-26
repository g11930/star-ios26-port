#!/bin/bash
# P32: P30 + rc.jobs (framewatch + four delayed com.annibale.unlock notifications).
# Boot from ABL's fastboot, then wait past loader_return_after=420 before touching the
# loader: a get_staged abandoned mid-transfer leaves the loader's fastboot wedged (P28).
export MSYS_NO_PATHCONV=1
A=/d/桌面/adb-fastboot/adb.exe
F=/d/桌面/adb-fastboot/fastboot.exe
DIR=/c/ios26
LOG=$DIR/p32-run.log
: > "$LOG"

echo "[$(date +%H:%M:%S)] rebooting to bootloader" >> "$LOG"
timeout 60 "$A" reboot bootloader >> "$LOG" 2>&1

for i in $(seq 1 60); do
	prod=$(timeout 10 "$F" getvar product 2>&1 | tr -d '\r' | grep -i "product:" | head -1)
	if [ -n "$prod" ]; then
		echo "[$i $(date +%H:%M:%S)] fastboot up: $prod" >> "$LOG"
		break
	fi
	sleep 2
done

echo "[$(date +%H:%M:%S)] fastboot boot p32-boot.img" >> "$LOG"
cd "$DIR" || exit 1
timeout 120 "$F" boot p32-boot.img >> "$LOG" 2>&1
echo "[$(date +%H:%M:%S)] boot command returned" >> "$LOG"

got=0
for i in $(seq 1 40); do
	sleep 20
	if [ $i -lt 24 ]; then
		continue
	fi
	echo "[$i $(date +%H:%M:%S)] checking" >> "$LOG"
	if timeout 10 "$F" devices 2>/dev/null | grep -qi "xnuloader"; then
		rm -f p32-staged.bin
		timeout 150 "$F" -s xnuloader get_staged p32-staged.bin >> "$LOG" 2>&1
		if [ -s p32-staged.bin ] && [ "$(stat -c %s p32-staged.bin)" -gt 65536 ]; then
			echo "[$i] staged: $(stat -c %s p32-staged.bin) bytes" >> "$LOG"
			got=1
			break
		fi
	fi
	if timeout 10 "$A" devices 2>/dev/null | grep -q "device$"; then
		echo "[$i] android is up; reading logdump" >> "$LOG"
		"$A" shell "su -c 'dd if=/dev/block/sda24 bs=4096 count=4096 2>/dev/null | base64'" > p32-logdump.b64 2>/dev/null
		tr -d '\r\n ' < p32-logdump.b64 | base64 -d > p32-logdump.bin 2>/dev/null
		if [ -s p32-logdump.bin ]; then
			cp -f p32-logdump.bin p32-staged.bin
			echo "[$i] logdump: $(stat -c %s p32-staged.bin) bytes" >> "$LOG"
			got=2
			break
		fi
	fi
done
echo "DONE got=$got" >> "$LOG"
