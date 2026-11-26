#!/bin/bash
echo "=== warsaw 参考日志里 logd 崩溃情况 ==="
W=/root/ref/warsaw/docs/v37/log-tail.txt
echo -n "warsaw logd 提及="; grep -aci "logd" "$W"
echo -n "warsaw logd xstat/crash="; grep -aciE "logd.*(xstat|crash|exit|SIGTRAP)" "$W"
grep -aiE "logd" "$W" | head -10
echo
echo "=== dada 参考补丁里有没有 logd / fsync / ramfs 相关修复 ==="
grep "^diff --git" /root/ref/dada/kernel/xnu-12377.121.6-dada.patch | grep -iE "ramfs|logd|ufs|fsync|vfs" | head -20
echo
echo "=== 我们树 logd 相关 boot-arg / 插桩 ==="
grep -rn "liblogdtrace\|applog\|logd" /root/star26/star-native/bsd/dev/star/star_platform_stubs.c 2>/dev/null | head -10
echo
echo "=== warsaw 参考 boot-args（对比 applog 设置） ==="
grep -a "boot-args" "$W" | head -2
