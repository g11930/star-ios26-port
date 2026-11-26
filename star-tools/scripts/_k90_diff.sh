#!/bin/bash
S=/root/star26/hackios-xnu-userland/userland/src/inject
K=/root/star26/k90ref/userland/userland/src/inject
echo "=== star inject 文件 ==="
ls "$S" 2>/dev/null | head -40
echo
echo "=== 同名文件 md5 对比 ==="
for f in $(ls "$K" 2>/dev/null); do
  if [ -f "$S/$f" ]; then
    m1=$(md5sum "$S/$f" | cut -d' ' -f1)
    m2=$(md5sum "$K/$f" | cut -d' ' -f1)
    if [ "$m1" = "$m2" ]; then tag=SAME; else tag=DIFF; fi
    printf "  %-42s %s\n" "$f" "$tag"
  else
    printf "  %-42s K90-ONLY\n" "$f"
  fi
done
echo
echo "=== 仅 star 有的 ==="
for f in $(ls "$S" 2>/dev/null); do
  if [ ! -f "$K/$f" ]; then echo "  $f"; fi
done
