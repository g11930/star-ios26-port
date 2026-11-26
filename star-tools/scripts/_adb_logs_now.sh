#!/bin/bash
# 只读：从安卓侧抓 logcat / dmesg / pstore，找 iOS 崩溃前后线索（Git Bash）
A="/d/桌面/adb-fastboot/adb.exe"
export MSYS_NO_PATHCONV=1
OUT=/c/ios26/adb-logs-$(date +%H%M%S)
mkdir -p "$OUT"
echo "OUT=$OUT"

echo "=== [1] device / boot state ==="
timeout 12 "$A" devices 2>&1 | tr -d '\r'
timeout 12 "$A" shell "getprop sys.boot_completed; getprop ro.boot.bootloader; getprop ro.build.version.release; getprop persist.sys.bootloader.version" 2>&1 | tr -d '\r'

echo "=== [2] logcat (last 800 lines) ==="
timeout 40 "$A" logcat -d -v threadtime -t 800 2>&1 | tr -d '\r' > "$OUT/logcat.txt"
wc -l "$OUT/logcat.txt"

echo "=== [3] dmesg (root, last 300) ==="
timeout 25 "$A" shell "su -c 'dmesg | tail -300'" 2>&1 | tr -d '\r' > "$OUT/dmesg.txt"
wc -l "$OUT/dmesg.txt"

echo "=== [4] pstore / last_kmsg ==="
timeout 25 "$A" shell "su -c 'ls -la /sys/fs/pstore/ 2>/dev/null; echo ---; cat /proc/last_kmsg 2>/dev/null | tail -80; echo ---; ls /sys/fs/pstore/* 2>/dev/null'" 2>&1 | tr -d '\r' > "$OUT/pstore.txt"
cat "$OUT/pstore.txt" | head -40

echo "=== [5] grep 关键词 ==="
grep -iE 'panic|haltRestart|kernel fault|non-platform|fastboot|bootloader| xnuloader|watchdog|reboot' "$OUT/logcat.txt" | tail -40

echo "=== DONE ==="
