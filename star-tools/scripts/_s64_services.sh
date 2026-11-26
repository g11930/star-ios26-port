#!/bin/bash
F=/mnt/c/ios26/s64-fresh2.bin
echo "=== 本轮 EXECDBG loading 的服务（去重计数） ==="
grep -ao "EXECDBG: loading [^ ]*" "$F" | sed 's#.*/##' | sort | uniq -c | sort -rn | head -50
echo
echo "=== 关键服务是否 exec ==="
for k in xpcproxy cfprefsd configd securityd lsd backboardd SpringBoard WindowServer logd notifyd usernotificationsd; do
  echo -n "$k loading="; grep -ac "EXECDBG: loading.*$k" "$F"
done
echo
echo "=== P28EXIT（进程退出） ==="
grep -aoE "P28EXIT: pid [0-9]+ [^ ]+" "$F" | sort | uniq -c | sort -rn | head -30
echo
echo "=== logd 崩溃 / 重启 / SIGTRAP（本轮真实） ==="
grep -aiE "logd|SIGTRAP|EXC_|crash|corpse|assert" "$F" | grep -viE "liblogdtrace|logdtrace|boot-args|library insertion" | head -30
