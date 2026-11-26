#!/bin/bash
# Wait for the s18 run to hand control back: the loader's own Fastboot debug
# mode shows up as `product: xnuloader`; a cold reset brings Android back.
export MSYS_NO_PATHCONV=1
cd /c/ios26 || exit 1
F=fastboot.exe
A=adb.exe
for i in $(seq 1 40); do
	sleep 5
	p=$(timeout 6 "$F" getvar product 2>&1 | tr -d '\r' | grep -i "product:" | head -1)
	d=$("$A" devices 2>/dev/null | grep -c "device$")
	echo "t=$((i*5))s  fb='${p:-none}'  adb=$d"
	case "$p" in
		*xnuloader*) echo "RESULT: loader debug mode (kernel returned)"; exit 0 ;;
		*star*)      echo "RESULT: ABL fastboot (cold reset happened)"; exit 0 ;;
	esac
	if [ "$d" != "0" ]; then echo "RESULT: android back"; exit 0; fi
done
echo "RESULT: still quiet after 200s"
