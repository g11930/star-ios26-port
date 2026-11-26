#!/bin/bash
echo "=== 本地是否有 launchd 源码 ==="
find /root/star26 -type f \( -name "*.c" -o -name "*.cpp" \) 2>/dev/null | xargs grep -l "no mach port for persistent services" 2>/dev/null | head -5
echo
echo "=== 在用户态树/二进制里搜这句 ==="
grep -rla "no mach port for persistent services" /root/star26/hackios-xnu-userland 2>/dev/null | head -5
echo
echo "=== launchd 二进制位置 ==="
find /root/star26 /mnt/c/ios26 -name "launchd" -type f 2>/dev/null | head -10
echo
echo "=== dada/warsaw 参考树是否提到这句 ==="
grep -rla "no mach port for persistent services\|persistent services" /root/ref/ 2>/dev/null | head -10
