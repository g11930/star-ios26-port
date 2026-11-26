#!/bin/bash
F=/mnt/c/ios26/s67-log1.bin
G=/mnt/c/ios26/s66-log-crash.bin
echo "=== 1. lsprobe CPU 采样（launchd/关键进程是否在耗 CPU） ==="
grep -a "lsprobe.*cpu procs" "$F" | tail -5
echo
echo "=== 2. lsprobe 进程表（launchd pid=1 是否在、进程数） ==="
grep -a "lsprobe.*procs=" "$F" | tail -3
echo
echo "=== 3. launchd 最后日志活动 ==="
grep -a "com.apple.xpc.launchd" "$F" | tail -8
echo
echo "=== 4. launchd 是否在接受其他服务的 check-in（xpcproxy 是否还在被 spawn） ==="
echo -n "s67 xpcproxy loading = "; grep -ac "EXECDBG: loading /usr/libexec/xpcproxy" "$F"
echo
echo "=== 5. 关键：SERVICE_PORT 的 mach service 名线索（launchd check-in 日志） ==="
grep -aiE "check.?in|bootstrap.*[0-9]|service.*port|com\.apple\.[a-z.]+:|moving to|claimed|published" "$F" | grep -a "launchd" | grep -viE "cmdline|boot-args|plist" | tail -20
echo
echo "=== 6. 对比能进桌面的 warsaw：backboardd 向 launchd check-in 后发生什么 ==="
grep -aiE "backboardd|check.?in|launchd" /root/ref/warsaw/docs/v37/log-tail.txt 2>/dev/null | grep -iE "backboard|check.?in" | head -15
