#!/bin/bash
# P33: the red-panel experiment. Boot from ABL's fastboot, wait past loader_return_after=420,
# then take the log. Starts from whichever state the phone is in: Android (adb), ABL fastboot
# (product: star) or the loader (product: xnuloader, which has no boot command of its own).
export MSYS_NO_PATHCONV=1
A=/d/桌面/adb-fastboot/adb.exe
F=/d/桌面/adb-fastboot/fastboot.exe
DIR=/c/ios26
LOG=$DIR/p40-run.log
: > "$LOG"

state=""
for i in $(seq 1 30); do
	prod=$(timeout 8 "$F" getvar product 2>&1 | tr -d '\r' | grep -i "product:" | head -1)
	if echo "$prod" | grep -qi "star"; then state=abl; echo "[$(date +%H:%M:%S)] ABL fastboot up" >> "$LOG"; break; fi
	if echo "$prod" | grep -qi "xnuloader"; then state=loader; echo "[$(date +%H:%M:%S)] loader up" >> "$LOG"; break; fi
	if timeout 8 "$A" devices 2>/dev/null | grep -q "device$"; then state=android; echo "[$(date +%H:%M:%S)] android up" >> "$LOG"; break; fi
	sleep 4
done
echo "[$(date +%H:%M:%S)] state=$state" >> "$LOG"

if [ "$state" = "loader" ]; then
	timeout 30 "$F" oem stop >> "$LOG" 2>&1
	for i in $(seq 1 60); do
		if timeout 8 "$A" devices 2>/dev/null | grep -q "device$"; then echo "[$(date +%H:%M:%S)] android after oem stop" >> "$LOG"; state=android; break; fi
		sleep 4
	done
fi

if [ "$state" = "android" ]; then
	timeout 60 "$A" reboot bootloader >> "$LOG" 2>&1
	for i in $(seq 1 40); do
		prod=$(timeout 8 "$F" getvar product 2>&1 | tr -d '\r' | grep -i "product:" | head -1)
		if echo "$prod" | grep -qi "star"; then echo "[$(date +%H:%M:%S)] ABL fastboot (after reboot)" >> "$LOG"; state=abl; break; fi
		sleep 3
	done
fi

if [ "$state" != "abl" ]; then
	echo "[$(date +%H:%M:%S)] cannot reach ABL fastboot; power the phone on into Android" >> "$LOG"
	exit 1
fi

echo "[$(date +%H:%M:%S)] fastboot boot p40-boot.img" >> "$LOG"
cd "$DIR" || exit 1
timeout 120 "$F" boot p40-boot.img >> "$LOG" 2>&1
echo "[$(date +%H:%M:%S)] boot command returned" >> "$LOG"

got=0
for i in $(seq 1 40); do
	sleep 20
	if [ $i -lt 16 ]; then
		continue
	fi
	echo "[$i $(date +%H:%M:%S)] checking" >> "$LOG"
	if timeout 10 "$F" devices 2>/dev/null | grep -qi "xnuloader"; then
		rm -f p40-staged.bin
		timeout 150 "$F" -s xnuloader get_staged p40-staged.bin >> "$LOG" 2>&1
		if [ -s p40-staged.bin ] && [ "$(stat -c %s p40-staged.bin)" -gt 65536 ]; then
			echo "[$i] staged: $(stat -c %s p40-staged.bin) bytes" >> "$LOG"
			got=1
			break
		fi
	fi
	if timeout 10 "$A" devices 2>/dev/null | grep -q "device$"; then
		echo "[$i] android is up; reading logdump" >> "$LOG"
		"$A" shell "su -c 'dd if=/dev/block/sda24 bs=4096 count=4096 2>/dev/null | base64'" > p40-logdump.b64 2>/dev/null
		tr -d '\r\n ' < p40-logdump.b64 | base64 -d > p40-logdump.bin 2>/dev/null
		if [ -s p40-logdump.bin ]; then
			cp -f p40-logdump.bin p40-staged.bin
			echo "[$i] logdump: $(stat -c %s p40-staged.bin) bytes" >> "$LOG"
			got=2
			break
		fi
	fi
done
echo "DONE got=$got" >> "$LOG"
