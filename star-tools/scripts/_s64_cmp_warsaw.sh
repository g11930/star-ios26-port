#!/bin/bash
W=/root/ref/warsaw/docs/v37/log-tail.txt
O=/mnt/c/ios26/s64-fresh6.bin
echo "=== warsaw 日志规模 ==="
wc -l "$W"
echo
echo "=== warsaw 关键服务 exec / 启动标记 ==="
for k in "xpcproxy" "cfprefsd" "configd" "securityd" "lsd" "SpringBoard" "backboardd" "WindowServer" "StartWindowServer" "userinfod" "SpringBoard: " "early boot complete" "Early boot complete" "boot task"; do
  echo -n "$k="; grep -aci "$k" "$W"
done
echo
echo "=== warsaw 是否也卡 mach_msg / wait ==="
grep -aiE "wait 7|mach_msg2|special reply|WAIT pc|port-wait" "$W" | head -20
echo
echo "=== warsaw 日志最后 50 行 ==="
tail -50 "$W"
