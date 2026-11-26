#!/bin/bash
# Poll the USB side without touching the device: the kernel is running and the
# loader will not answer until its watchdog (50 s) or loader_return_after=200
# hands control back.  `oem log` is forbidden here -- in a returned state it
# composes NULL/0 and erases the kernel section we want.
export MSYS_NO_PATHCONV=1
cd /c/ios26 || exit 1
F=fastboot.exe
A=adb.exe

for i in $(seq 1 40); do
	p=$(timeout 6 "$F" getvar product 2>&1 | tr -d '\r' | grep -i "product:" | head -1)
	if [ -n "$p" ]; then
		echo "[$((i*10))s] fastboot: $p"
		case "$p" in
			*xnuloader*|*star*) echo "STATE: $p"; exit 0 ;;
		esac
	else
		if "$A" devices 2>/dev/null | grep -q "device$"; then
			echo "[$((i*10))s] android is up"
			exit 0
		fi
		echo "[$((i*10))s] no fastboot, no adb"
	fi
	sleep 10
done
echo "STATE: nothing after 400s"
