#!/bin/bash
echo "=== 1. warsaw 文档里所有提到 mkcache / job 缓存 / sleepd / service label 的地方 ==="
grep -rniE "mkcache|job cache|sleepd|sleepserver|label.*cache|cache.*label|service.*missing|missing.*service" /root/ref/warsaw/docs/ /root/ref/dada/ 2>/dev/null | grep -viE "\.patch:" | head -60

echo
echo "=== 2. 我们系统盘里的 launchd cache（extensions.plist / launchd.plist） ==="
echo "warsaw extensions.plist 大小："
ls -la /root/star26/s66/work/root/xpc/ 2>/dev/null | head
echo "我们的："
ls -la /root/star26/s66/work/root/xpc/extensions.plist* 2>/dev/null

echo
echo "=== 3. sleepd 在我们 job 缓存/系统里存在吗 ==="
grep -a "com.apple.sleepd" /root/star26/s66/work/root/xpc/launchd.plist 2>/dev/null | head -3
echo "s66 root 里 sleepd 相关文件："
find /root/star26/s66/work/root -iname "*sleepd*" 2>/dev/null | head

echo
echo "=== 4. warsaw 的 mkcache.py 或 job 生成工具 ==="
find /root/ref -iname "*mkcache*" -o -iname "*cache*.py" 2>/dev/null | head -20
