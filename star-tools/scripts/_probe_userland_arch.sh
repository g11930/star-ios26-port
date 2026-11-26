#!/bin/bash
# 只读：探测我们容器里的用户态架构 + arm64/arm64e 内核备份差异
echo "===== 1. ipsw 目录 ====="
ls -la /root/star26/ipsw/ 2>/dev/null

echo ""
echo "===== 2. 内核备份架构 (mach.arm64.bak vs mach.arm64e-s19.bak) ====="
for k in /root/star26/mach.arm64.bak /root/star26/mach.arm64e-s19.bak; do
  echo "--- $k ---"
  file "$k" 2>/dev/null
  md5sum "$k" 2>/dev/null
done

echo ""
echo "===== 3. 找现成的 dyld cache / launchd / dyld / IPSW (整个 star26 + ios26 挂载点) ====="
find /root/star26 /mnt/c/ios26 /mnt/d/ios26 -maxdepth 6 \
  \( -iname "dyld_shared_cache*" -o -iname "launchd" -o -iname "dyld" -o -iname "*.ipsw" -o -iname "*.dmg" \) 2>/dev/null | head -80

echo ""
echo "===== 4. baseline 里 ramdisk/dylib 组件清单 (s217parts) ====="
ls -lah /root/star26/baseline/s217parts/ 2>/dev/null

echo ""
echo "===== 5. ramdisk 内容：是否含 arm64e 用户态 ====="
ls -lah /root/star26/baseline/s217parts/* 2>/dev/null | head -40
