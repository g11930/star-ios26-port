#!/bin/bash
F=/root/star26/star-native/osfmk/arm64/sleh.c
echo "=== 1260-1290: 状态与 fips 闸门 ==="
sed -n '1260,1290p' "$F"
echo
echo "=== 1436-1545: pac_patch_page 完整 ==="
sed -n '1436,1545p' "$F"
echo
echo "=== 1600-1680: PAC 模拟 + 调用 page ==="
sed -n '1600,1680p' "$F"
