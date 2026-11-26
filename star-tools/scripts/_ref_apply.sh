#!/bin/bash
F=/mnt/c/ios26/s67-log1.bin
echo "=== 1. 我们日志里有没有 lookup 失败 / 服务缺失（用户态错误） ==="
grep -aiE "lookup with error|invalidated|No such process|4099|failed to connect|HKSPSleepStore|sleepd|sleepserver|could not find|bootstrap.*fail|lookup.*fail" "$F" | grep -viE "cmdline|boot-args" | head -40
echo
echo "=== 2. backboardd 的所有用户态 trace（say 39） ==="
grep -a "say 39" "$F" | grep -viE "^say 39 trace: (image|\+image|interposing|ctor|heartbeat|SIGPROF|beat [0-9]|wait [0-9]|originals)" | head -40
echo
echo "=== 3. 我们 job 缓存里有多少 label（extensions.plist） ==="
grep -ao "com\.apple\.[A-Za-z0-9._-]*" /root/star26/s66/work/root/xpc/extensions.plist 2>/dev/null | sort -u | wc -l
echo "sleepd 在不在 extensions.plist："
grep -ac "sleepd" /root/star26/s66/work/root/xpc/extensions.plist 2>/dev/null
echo
echo "=== 4. 我们的 launchd.plist 有多少 label ==="
grep -ao "<key>com\.apple\.[A-Za-z0-9._-]*</key>" /root/star26/s66/work/root/xpc/launchd.plist 2>/dev/null | wc -l
echo
echo "=== 5. warsaw README 里关于补齐缓存/service 的操作 ==="
find /root/ref/warsaw -maxdepth 2 -iname "README*" 2>/dev/null | head -5
