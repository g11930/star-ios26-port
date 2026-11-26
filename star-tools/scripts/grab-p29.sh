#!/bin/bash
# P29's log. Waits past loader_return_after=420 before touching the loader: a get_staged
# that is abandoned mid-transfer leaves the loader's fastboot wedged (P28's run).
export MSYS_NO_PATHCONV=1
A=/d/桌面/adb-fastboot/adb.exe
F=/d/桌面/adb-fastboot/fastboot.exe
DIR=/c/ios26
LOG=$DIR/p29-run.log
: > "$LOG"

echo "[$(date +%H:%M:%S)] booted; waiting 470 s" >> "$LOG"
sleep 470

got=0
for i in $(seq 1 30); do
	echo "[$i $(date +%H:%M:%S)] checking" >> "$LOG"
	if timeout 10 "$F" devices 2>/dev/null | grep -qi "xnuloader"; then
		rm -f p29-staged.bin
		timeout 150 "$F" -s xnuloader get_staged p29-staged.bin >> "$LOG" 2>&1
		if [ -s p29-staged.bin ] && [ "$(stat -c %s p29-staged.bin)" -gt 65536 ]; then
			echo "[$i] staged: $(stat -c %s p29-staged.bin) bytes" >> "$LOG"
			got=1
			break
		fi
	fi
	if timeout 10 "$A" devices 2>/dev/null | grep -q "device$"; then
		echo "[$i] android is up; reading logdump" >> "$LOG"
		"$A" shell "su -c 'dd if=/dev/block/sda24 bs=4096 count=4096 2>/dev/null | base64'" > p29-logdump.b64 2>/dev/null
		tr -d '\r\n ' < p29-logdump.b64 | base64 -d > p29-logdump.bin 2>/dev/null
		if [ -s p29-logdump.bin ]; then
			cp -f p29-logdump.bin p29-staged.bin
			echo "[$i] logdump: $(stat -c %s p29-staged.bin) bytes" >> "$LOG"
			got=2
			break
		fi
	fi
	sleep 20
done
echo "DONE got=$got" >> "$LOG"
