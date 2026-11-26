#!/bin/bash
# Get the phone back to a flashable fastboot and flash one s14 image at checkpoint $1.
# After a checkpoint return the loader sits in its own Fastboot debug mode, whose
# `boot` command does not exist -- so the phone has to go to Android first, and then
# to the *ABL* fastboot, before `fastboot boot` works again.
export MSYS_NO_PATHCONV=1
CP=$1
cd /c/ios26 || exit 1
F=fastboot.exe
A=adb.exe

p=$(timeout 8 "$F" getvar product 2>&1 | tr -d '\r' | grep -i "product:" | head -1)
case "$p" in
	*xnuloader*)
		echo "in the loader's debug mode: rebooting it"
		timeout 15 "$F" -s xnuloader reboot >/dev/null 2>&1
		;;
esac
for i in $(seq 1 25); do
	sleep 3
	if "$A" devices 2>/dev/null | grep -q "device$"; then echo "android at try $i"; break; fi
done
sleep 2
"$A" reboot bootloader >/dev/null 2>&1
for i in $(seq 1 25); do
	sleep 3
	p=$(timeout 8 "$F" getvar product 2>&1 | tr -d '\r' | grep -i "product:" | head -1)
	case "$p" in *star*) echo "fastboot: $p"; break ;; esac
done
wsl.exe -d Ubuntu-24.04 -e bash -lc "python3 /mnt/d/桌面/star26-deps/scripts/make-s14.py $CP 2>&1 | tail -3" | tr -d '\000' | sed 's/\r//'
echo "flashing checkpoint $CP"
timeout 150 "$F" boot s14-boot.img 2>&1 | tr -d '\r' | tail -2
