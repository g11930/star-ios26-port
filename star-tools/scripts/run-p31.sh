#!/bin/bash
# P31: P30 + the display driver's screen recording (rec_secs/rec_start/rec_mb/rec_ring).
# Order matters: the loader stages the kernel log when it takes the machine back, so get_staged
# FIRST, then "oem recording" (which only re-points the staged buffer), then get_staged again.
export MSYS_NO_PATHCONV=1
A=/d/桌面/adb-fastboot/adb.exe
F=/d/桌面/adb-fastboot/fastboot.exe
DIR=/c/ios26
LOG=$DIR/p31-run.log
IMG=${1:-p31-boot.img}
: > "$LOG"

# If the loader still owns the machine (the run before this one), cold reset it first: its
# "reboot" is EfiResetCold, which lands in ABL, and only ABL can boot our image.
prod0=$(timeout 10 "$F" getvar product 2>&1 | tr -d '\r' | grep -i "product:" | head -1)
echo "[$(date +%H:%M:%S)] start state: ${prod0:-nothing}" >> "$LOG"
if echo "$prod0" | grep -qi "xnuloader"; then
	echo "[$(date +%H:%M:%S)] loader holds the phone; cold reset" >> "$LOG"
	timeout 30 "$F" reboot >> "$LOG" 2>&1
	for i in $(seq 1 60); do
		if timeout 10 "$A" devices 2>/dev/null | grep -q "device$"; then
			echo "[$i $(date +%H:%M:%S)] android is up" >> "$LOG"
			break
		fi
		sleep 3
	done
fi

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

echo "[$(date +%H:%M:%S)] fastboot boot $IMG" >> "$LOG"
cd "$DIR" || exit 1
timeout 120 "$F" boot "$IMG" >> "$LOG" 2>&1
echo "[$(date +%H:%M:%S)] boot command returned" >> "$LOG"

got=0
for i in $(seq 1 45); do
	sleep 20
	if [ $i -lt 24 ]; then
		continue
	fi
	echo "[$i $(date +%H:%M:%S)] checking" >> "$LOG"
	if timeout 10 "$F" devices 2>/dev/null | grep -qi "xnuloader"; then
		# 1. the kernel log the loader staged when the kernel returned
		rm -f p31-staged.bin
		timeout 150 "$F" -s xnuloader get_staged p31-staged.bin >> "$LOG" 2>&1
		if [ -s p31-staged.bin ] && [ "$(stat -c %s p31-staged.bin)" -gt 65536 ]; then
			echo "[$i] staged log: $(stat -c %s p31-staged.bin) bytes" >> "$LOG"
			got=1
		fi
		# 2. the screen recording the display driver left in memory
		echo "[$i] oem recording" >> "$LOG"
		timeout 60 "$F" -s xnuloader oem recording >> "$LOG" 2>&1
		rm -f p31-rec.bin
		timeout 300 "$F" -s xnuloader get_staged p31-rec.bin >> "$LOG" 2>&1
		if [ -s p31-rec.bin ] && [ "$(stat -c %s p31-rec.bin)" -gt 4096 ]; then
			echo "[$i] recording: $(stat -c %s p31-rec.bin) bytes" >> "$LOG"
			got=$((got + 2))
		fi
		[ $got -gt 0 ] && break
	fi
	if timeout 10 "$A" devices 2>/dev/null | grep -q "device$"; then
		echo "[$i] android is up; reading logdump" >> "$LOG"
		"$A" shell "su -c 'dd if=/dev/block/sda24 bs=4096 count=4096 2>/dev/null | base64'" > p31-logdump.b64 2>/dev/null
		tr -d '\r\n ' < p31-logdump.b64 | base64 -d > p31-logdump.bin 2>/dev/null
		if [ -s p31-logdump.bin ]; then
			cp -f p31-logdump.bin p31-staged.bin
			echo "[$i] logdump: $(stat -c %s p31-staged.bin) bytes" >> "$LOG"
			got=2
			break
		fi
	fi
done
echo "DONE got=$got" >> "$LOG"
