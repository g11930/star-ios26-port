#!/bin/bash
echo "=== s58 root tree 里 annibale/bin 全部内容 ==="
ls -la /root/star26/s58/work/root/annibale/bin/ 2>/dev/null
echo
echo "=== s58 root tree 里所有 starcat 路径 ==="
find /root/star26/s58/work/root -name starcat 2>/dev/null
echo
echo "=== starcat 的 -p 前缀匹配逻辑（确认支持 logd） ==="
grep -n -A20 -B5 '"-p"\|starts_with.*prefix\|prefix\|rx_name\|na.name' /mnt/d/桌面/star26-deps/scripts/starcat.c | head -80
echo
echo "=== s39 starcat 二进制架构确认 ==="
file /root/star26/s39/work/starcat 2>/dev/null
