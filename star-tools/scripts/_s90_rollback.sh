#!/bin/bash
# 回退到 s90：从当前 xnuloader 状态跳出 -> Android -> ABL fastboot -> boot s90。
# 跳出前先取回 s93 活日志（若有），不丢诊断数据。
export MSYS_NO_PATHCONV=1
F=/mnt/d/桌面/adb-fastboot/fastboot.exe
A=/mnt/d/桌面/adb-fastboot/adb.exe
cd /mnt/c/ios26 || exit 1

echo "=== [$(date +%T)] STEP 0: grab s93 live log before leaving loader ==="
rm -f /mnt/c/ios26/s93-staged.bin
timeout 40 "$F" -s xnuloader get_staged "C:/ios26/s93-staged.bin" 2>&1 | tr -d '\r' | tail -3
if [ -s /mnt/c/ios26/s93-staged.bin ]; then
	echo "captured s93 staged: $(stat -c %s /mnt/c/ios26/s93-staged.bin) bytes"
else
	echo "no staged bytes (loader may not have staged a log yet)"
fi

echo "=== [$(date +%T)] STEP 1: reboot out of xnuloader -> Android ==="
timeout 15 "$F" -s xnuloader reboot 2>&1 | tr -d '\r' | tail -2 || true
ok=0
for i in $(seq 1 40); do
	sleep 2
	ad=$("$A" devices 2>/dev/null | tr -d '\r' | grep -c "device$")
	if [ "$ad" -gt 0 ]; then echo "android back at try $i"; ok=1; break; fi
	if [ $((i % 10)) -eq 0 ]; then
		p=$(timeout 5 "$F" getvar product 2>&1 | tr -d '\r' | grep -i product: | head -1)
		echo "  waiting android... prod='${p:-none}'"
	fi
done
if [ "$ok" != "1" ]; then echo "WARN: android not seen; will try fastboot path anyway"; fi

echo "=== [$(date +%T)] STEP 2: adb reboot bootloader ==="
"$A" reboot bootloader >/dev/null 2>&1
fb=0
for i in $(seq 1 40); do
	sleep 2
	p=$(timeout 6 "$F" getvar product 2>&1 | tr -d '\r' | grep -i "product:" | head -1)
	case "$p" in
		*star*) echo "ABL fastboot: $p (try $i)"; fb=1; break ;;
		*xnuloader*) echo "still xnuloader (try $i); rebooting out again"; timeout 15 "$F" -s xnuloader reboot >/dev/null 2>&1; sleep 3 ;;
	esac
	if [ $((i % 10)) -eq 0 ]; then echo "  waiting ABL fastboot... prod='${p:-none}'"; fi
done
if [ "$fb" != "1" ]; then echo "ABORT: cannot reach ABL fastboot"; exit 3; fi

echo "=== [$(date +%T)] STEP 3: fastboot boot s90-boot.img ==="
timeout 200 "$F" boot "C:/ios26/s90-boot.img" 2>&1 | tr -d '\r' | tail -5

echo "=== [$(date +%T)] STEP 4: wait ~40s then check loader result ==="
sleep 40
timeout 8 "$F" -s xnuloader getvar result 2>&1 | tr -d '\r' | head -2 || true
timeout 8 "$F" getvar product 2>&1 | tr -d '\r' | head -2

echo "=== [$(date +%T)] DONE (s90 booted)"
