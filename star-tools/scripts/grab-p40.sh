#!/bin/bash
# Grab the P40 kernel log in the short window after the 420s kernel returns,
# before the USB link dies. The logdump partition is stale (P21 era), so this
# get_staged window is the only way to see this run's own log.
export MSYS_NO_PATHCONV=1
F=/d/桌面/adb-fastboot/fastboot.exe
A=/d/桌面/adb-fastboot/adb.exe
DIR=/c/ios26
cd "$DIR" || exit 1
rm -f p40-manual.bin
for i in $(seq 1 100); do
	prod=$(timeout 6 "$F" getvar product 2>&1 | tr -d '\r' | grep -i "product:" | head -1)
	if echo "$prod" | grep -qi "xnuloader"; then
		echo "[$(date +%H:%M:%S)] xnuloader seen, grabbing staged"
		timeout 150 "$F" -s xnuloader get_staged p40-manual.bin 2>&1 | tail -3
		if [ -s p40-manual.bin ]; then
			echo "[$(date +%H:%M:%S)] grabbed $(stat -c %s p40-manual.bin) bytes"
			exit 0
		fi
	fi
	if timeout 6 "$A" devices 2>/dev/null | grep -q "device$"; then
		echo "[$(date +%H:%M:%S)] android is up (staged window likely gone)"
	fi
	if [ $((i % 12)) -eq 0 ]; then
		echo "[$(date +%H:%M:%S)] poll $i: $prod"
	fi
	sleep 5
done
echo "TIMEOUT: no staged log"
exit 1
