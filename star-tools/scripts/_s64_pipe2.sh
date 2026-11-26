#!/bin/bash
echo "=== 1. 全树搜 half lowering / ALU fmax ==="
grep -rn "half lowering does not support" /root/star26/ 2>/dev/null | head -10
echo "--- ALU fmax ---"
grep -rn "ALU fmax" /root/star26/ 2>/dev/null | head -10

echo
echo "=== 2. 搜 softpipe / llvmpipe / lavapipe / swiftshader ==="
for k in softpipe llvmpipe lavapipe swiftshader SwiftShader; do
  echo "--- $k ---"
  grep -rli "$k" /root/star26/ 2>/dev/null | head -8
done

echo
echo "=== 3. 用户态 GPU/metal 相关目录 ==="
ls -d /root/star26/hackios-xnu-userland/userland/src/* 2>/dev/null | head -60

echo
echo "=== 4. metal 驱动源码位置 ==="
find /root/star26 -iname "*metal*" -type f 2>/dev/null | grep -viE "\.o$|\.d$|BUILD/" | head -30
