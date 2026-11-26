#!/bin/bash
# Thorough read-only diagnosis: where is a compiler + SDK that can build arm64e (PAC) dylibs?
echo "=== [1] all xnu-clang binaries ==="
find /root -type f -name xnu-clang 2>/dev/null | while read f; do
  echo "--- $f ---"
  head -3 "$f" 2>/dev/null
done

echo ""
echo "=== [2] all iPhoneOS SDK roots (incl. 26 symlink farms) ==="
find /root /opt /mnt/c /mnt/d -maxdepth 9 -type d \( -name "iPhoneOS*.sdk" -o -name "iPhoneOS.sdk" \) 2>/dev/null | head -40

echo ""
echo "=== [3] Xcode toolchains / clang with arm64e PAC support ==="
find /root /opt /mnt/c -maxdepth 8 -type f \( -name "clang" -o -name "clang-*" \) 2>/dev/null | head -40

echo ""
echo "=== [4] star26 xnu-deps/26 tree ==="
ls -laR /root/star26/hackios-xnu-userland/xnu-deps/ 2>/dev/null | head -60
ls -laR /root/star26/xnu-deps/ 2>/dev/null | head -40

echo ""
echo "=== [5] K90 release: any SDK/build hints ==="
find /d/桌面/star26-deps/k90-ref/v021 -maxdepth 3 -type f 2>/dev/null | head -30
