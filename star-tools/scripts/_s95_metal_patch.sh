#!/bin/bash
# s95 = s94 (CS补丁) + s91 式无条件 Metal setProperty。单变量（相对 s94 仅 Metal 一处）。
set -e
K=/root/star26/star-native/iokit/Kernel/MiniFramebufferUserClient.inc
echo "=== 1) backup current (s94 Metal guard state) ==="
cp -f "$K" "$K.s95-pre-metal.bak"
md5sum "$K" "$K.s95-pre-metal.bak"

echo "=== 2) show exact guard block to remove ==="
sed -n '463,470p' "$K"
