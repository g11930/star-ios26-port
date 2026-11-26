#!/bin/bash
# Boot s17 (stage-13/14 tracing kernel, no checkpoint) once.
# After a checkpoint / watchdog return the loader sits in its own Fastboot debug
# mode whose `boot` command does not exist, so Android must come up first and
# only then can we reach the ABL fastboot that does have `boot`.
export MSYS_NO_PATHCONV=1
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
ls -la s17-boot.img
echo "flashing s17"
timeout 200 "$F" boot s17-boot.img 2>&1 | tr -d '\r' | tail -3
echo "--- done, watch the phone screen for STARX lines in the KERNEL BOOT CONSOLE card"
