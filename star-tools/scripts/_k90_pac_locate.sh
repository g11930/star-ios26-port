#!/bin/bash
echo "=== K90 参考树候选位置 ==="
for d in /root/star26/k90ref/kernel /root/k90-src /root/ref2/annibale-kernel /root/star26/k90ref; do
  [ -d "$d" ] && echo "EXISTS $d : $(find "$d" -maxdepth 2 -type d 2>/dev/null | wc -l) dirs"
done
echo
echo "=== K90 树里 PAC / ptrauth 相关文件 ==="
for d in /root/star26/k90ref/kernel /root/k90-src /root/ref2/annibale-kernel; do
  [ -d "$d" ] || continue
  echo "--- $d ---"
  grep -rl -i -E 'pac_patch|ptrauth|paciasp|PAuth|FEAT_PAuth|sleh' "$d" 2>/dev/null | head -25
done
