#!/bin/bash
# run-img.sh <image-name-in-c:/ios26>   e.g. run-img.sh s18c-boot.img
# Leaves the device in Android, then fastboot-boots the given image once.
export MSYS_NO_PATHCONV=1
IMG="$1"
[ -z "$IMG" ] && { echo "usage: run-img.sh <img>"; exit 1; }
cd /c/ios26 || exit 1
F=fastboot.exe
A=adb.exe

p=$(timeout 8 "$F" getvar product 2>&1 | tr -d '\r' | grep -i "product:" | head -1)
echo "start: ${p:-<no fastboot>}"
case "$p" in
	*xnuloader*)
		echo "in the loader's debug mode: rebooting it"
		timeout 15 "$F" -s xnuloader reboot >/dev/null 2>&1
		;;
esac
for i in $(seq 1 30); do
	sleep 3
	if "$A" devices 2>/dev/null | grep -q "device$"; then echo "android at try $i"; break; fi
done
sleep 2
"$A" reboot bootloader >/dev/null 2>&1
for i in $(seq 1 30); do
	sleep 3
	p=$(timeout 8 "$F" getvar product 2>&1 | tr -d '\r' | grep -i "product:" | head -1)
	case "$p" in *star*) echo "fastboot: $p"; break ;; esac
done
ls -la "$IMG"
echo "flashing $IMG"
timeout 200 "$F" boot "$IMG" 2>&1 | tr -d '\r' | tail -3
echo "--- done"
