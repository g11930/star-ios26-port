#!/bin/bash
echo "=== [1] dtb/dtbo files on D: (project + ios26) ==="
find /mnt/d/ios26 /mnt/d/桌面/star26-deps -maxdepth 4 -type f \( -name "*.dtb" -o -name "*.dtbo" -o -name "*dtb*" \) 2>/dev/null | head -30
echo
echo "=== [2] any binary dtb containing the string gpu-pwrlevels ==="
for d in /mnt/d/ios26 /mnt/d/桌面/star26-deps/firmware /mnt/d/桌面/star26-deps/release; do
  [ -d "$d" ] || continue
  echo "-- $d"
  grep -rl "gpu-pwrlevels" "$d" 2>/dev/null | head -10
done
echo
echo "=== [3] firmware dirs we keep for the GPU ==="
find /root/star26/baseline -iname "a660*" 2>/dev/null | head -20
find /mnt/d/ios26 -iname "a660*" 2>/dev/null | head -20
echo
echo "=== [4] memory notes mentioning gpu level / 550 / 840 ==="
grep -rn -i "gpu" /mnt/d/桌面/star-ios16-stable-documented-20261030/.workbuddy/memory/*.md 2>/dev/null | grep -i -E "550|840|level|档|调频" | head -20
