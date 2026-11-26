#!/bin/bash
# Boot s18 and grab the staged log the instant the loader's own Fastboot mode
# appears.
#
# Why: a checkpoint that hits while the kernel holds UFS comes back as
# `checkpoint-held`, and in that state the loader deliberately does not write
# logdump (the kernel owns the controller).  The bytes stay in the loader's
# staging area and `get_staged` is the only way out -- and the window is short
# before the loader reboots itself.  So do not poll first: fire get_staged
# right after `Booting OKAY` and let fastboot block on "< waiting for>".
export MSYS_NO_PATHCONV=1
cd /c/ios26 || exit 1
F=fastboot.exe
A=adb.exe
OUT=${1:-s18-staged.bin}

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

rm -f "$OUT"
ls -la s18-boot.img
echo "flashing s18"
timeout 200 "$F" boot s18-boot.img 2>&1 | tr -d '\r' | tail -3

echo "--- grabbing the staged log (blocking wait for the loader's own fastboot)"
for try in 1 2 3; do
	echo "  attempt $try"
	timeout 150 "$F" -s xnuloader get_staged "$OUT" 2>&1 | tr -d '\r' | tail -4
	if [ -s "$OUT" ]; then echo "  got $(stat -c %s "$OUT") bytes"; break; fi
	sleep 2
done
ls -la "$OUT" 2>/dev/null || echo "  no staged log captured"
