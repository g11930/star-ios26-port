#!/bin/bash
# Watch what happens after booting s19: either Android comes back (kernel died /
# WDT reset) or fastboot still says xnuloader past the early-usb window, which
# means the kernel stopped at a checkpoint and handed control back to the loader.
export MSYS_NO_PATHCONV=1
cd /c/ios26 || exit 1
F=fastboot.exe
A=adb.exe
t0=$(date +%s)
for i in $(seq 1 60); do
	sleep 3
	now=$(( $(date +%s) - t0 ))
	ad=$("$A" devices 2>/dev/null | grep -c "device$")
	fb=$(timeout 6 "$F" getvar product 2>&1 | tr -d '\r' | grep -i "product:" | head -1)
	if [ "$ad" -gt 0 ]; then
		echo "[${now}s] ANDROID BACK  (kernel died / reset)"
		exit 0
	fi
	case "$fb" in
		*star*) echo "[${now}s] ABL fastboot: $fb"; exit 0 ;;
		*xnuloader*) echo "[${now}s] xnuloader: $fb" ;;
		*) echo "[${now}s] -" ;;
	esac
done
echo "[240s] timeout"
