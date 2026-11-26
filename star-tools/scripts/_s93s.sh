#!/bin/bash
echo "=== A. 找最近的 boot log / staged dump ==="
find /mnt/d/桌面 -maxdepth 3 \( -name '*.log' -o -name '*staged*' -o -name '*.bin' \) -newermt '2026-11-16' 2>/dev/null | head -40
echo
echo "=== B. D:/桌面/star26-deps/tmp 内容 ==="
ls -lt /mnt/d/桌面/star26-deps/tmp/ 2>/dev/null | head -30
echo
echo "=== C. D:/桌面/star26-deps/引导 内容 ==="
ls -lt /mnt/d/桌面/star26-deps/引导/ 2>/dev/null | head -30
echo
echo "=== D. 桌面顶层最近文件 ==="
ls -lt /mnt/d/桌面/ 2>/dev/null | head -30
echo
echo "=== E. star-ios16 项目目录最近文件 ==="
ls -lt "/mnt/d/桌面/star-ios16-stable-documented-20261030/" 2>/dev/null | head -30
echo "=== DONE ==="
