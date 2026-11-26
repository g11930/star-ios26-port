#!/bin/bash
# Wait for Android to come back, then say how long the kernel ran.
# The loader serves its own Fastboot (`product: xnuloader`) during early boot as
# well, so that is NOT a return signal -- only adb coming back is.
export MSYS_NO_PATHCONV=1
cd /c/ios26 || exit 1
F=fastboot.exe
A=adb.exe
for i in $(seq 1 40); do
	sleep 5
	d=$("$A" devices 2>/dev/null | grep -c "device$")
	p=$(timeout 6 "$F" getvar product 2>&1 | tr -d '\r' | grep -i "product:" | head -1)
	echo "t=$((i*5))s  adb=$d  fb='${p:-none}'"
	if [ "$d" != "0" ]; then echo "RESULT: android back at $((i*5))s"; exit 0; fi
done
echo "RESULT: still quiet after 200s"
