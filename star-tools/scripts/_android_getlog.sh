#!/bin/bash
# 从 xnuloader 回 Android，取 Android 侧日志（logcat + dmesg + 关键状态）。
export MSYS_NO_PATHCONV=1
F=/mnt/d/桌面/adb-fastboot/fastboot.exe
A=/mnt/d/桌面/adb-fastboot/adb.exe
OUT=/mnt/c/ios26/android-side-log.txt
: > "$OUT"

echo "=== [$(date +%T)] current state ===" | tee -a "$OUT"
timeout 8 "$F" getvar product 2>&1 | tr -d '\r' | grep -i product: | head -1 | tee -a "$OUT"

echo "=== [$(date +%T)] reboot out of xnuloader ===" | tee -a "$OUT"
timeout 15 "$F" -s xnuloader reboot 2>&1 | tr -d '\r' | tail -2 | tee -a "$OUT" || true

ok=0
for i in $(seq 1 45); do
	sleep 2
	ad=$("$A" devices 2>/dev/null | tr -d '\r' | grep -c "device$")
	if [ "$ad" -gt 0 ]; then echo "android back at try $i" | tee -a "$OUT"; ok=1; break; fi
	if [ $((i % 10)) -eq 0 ]; then echo "  waiting android ($i)..." | tee -a "$OUT"; fi
done
if [ "$ok" != "1" ]; then echo "ABORT: android not back" | tee -a "$OUT"; exit 2; fi

echo "=== [$(date +%T)] key properties ===" | tee -a "$OUT"
"$A" shell "getprop ro.build.version.release; getprop ro.product.model; getprop ro.bootmode; getprop persist.sys.usb.config" 2>&1 | tr -d '\r' | tee -a "$OUT"

echo "=== [$(date +%T)] logcat -d (last 800 lines) ===" | tee -a "$OUT"
"$A" logcat -d -v threadtime 2>&1 | tr -d '\r' | tail -800 >> "$OUT"

echo "=== [$(date +%T)] dmesg (last 300 lines) ===" | tee -a "$OUT"
"$A" shell "dmesg" 2>&1 | tr -d '\r' | tail -300 >> "$OUT"

echo "=== [$(date +%T)] size ===" | tee -a "$OUT"
stat -c '%s bytes' "$OUT" | tee -a "$OUT"
echo "=== [$(date +%T)] DONE ===" | tee -a "$OUT"
