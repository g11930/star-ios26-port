#!/bin/bash
echo "=== 1. 在 XNU 源码里搜 11600/11603 或 0x2d50/0x2d53 ==="
grep -rnE "11600|11603|0x2d50|0x2d53|0x2D50|0x2D53" /root/star26/star-native/osfmk /root/star26/star-native/bsd 2>/dev/null | head -20
echo
echo "=== 2. 在用户态头文件/sdk 里搜 ==="
grep -rnE "= 11600|= 11603|0x2d50|0x2d53" /root/star26/hackios-xnu-userland 2>/dev/null | head -20
echo
echo "=== 3. launchd/XPC message id 常见定义（bootstrap 相关） ==="
grep -rnE "MACH_MSG_ID|msgh_id|BOOTSTRAP.*MSG|message.*id" /root/star26/hackios-xnu-userland/userland/include 2>/dev/null | grep -iE "bootstrap|xpc|launchd" | head -20
echo
echo "=== 4. 从 launchd 二进制 strings 找线索 ==="
find /root/star26 -name "launchd" -type f 2>/dev/null | head -5
echo
echo "=== 5. 11600 十进制附近是否有已知 XPC id（看 dada/warsaw 文档） ==="
grep -rnE "11600|11603|2d50|2d53|msgh_id" /root/ref 2>/dev/null | grep -viE "Binary file" | head -20
