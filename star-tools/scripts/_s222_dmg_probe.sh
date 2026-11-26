#!/bin/bash
# 只读：探测 IPSW dmg 能否提取完整 dyld shared cache
echo "===== 1. dmg 文件类型 ====="
for d in /root/star26/ipsw/*.dmg; do
  echo "--- $(basename $d) ---"
  ls -lh "$d" | awk '{print $5}'
  file "$d"
done

echo ""
echo "===== 2. 可用的 dmg 提取工具 ====="
for t in 7z 7za dmg2img hdiutil mount fuse-ext2 apfs-fuse; do
  which $t 2>/dev/null && echo "  $t OK" || echo "  $t MISSING"
done

echo ""
echo "===== 3. 是否已挂载 ====="
mount | grep -iE 'os.dmg|systemos|appos|loop' | head -20 || echo "  none mounted"

echo ""
echo "===== 4. 找我们之前提取 cache 的痕迹 (kcachetal 之类) ====="
find /root/star26 -maxdepth 4 -type d \( -iname "*cache*" -o -iname "*dyld*" -o -iname "*extract*" \) 2>/dev/null | head -30

echo ""
echo "===== 5. dmg 头部魔数 (确认是否加密/可挂载) ====="
for d in /root/star26/ipsw/*.dmg; do
  echo -n "$(basename $d): "
  xxd -l 16 "$d" 2>/dev/null | head -1
done
