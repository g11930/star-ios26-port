#!/bin/bash
F=/root/star26/star-native/bsd/dev/star/annibale_adreno.c
echo "===== tsens 定义块精确行号 ====="
grep -n "beside the steps: how warm\|static struct block tsens\|#define TSENS_STATUS\|#define TSENS_VALID\|struct block tsens" "$F"
echo "===== struct block 类型定义位置 ====="
grep -rn "struct block {" "$F" /root/star26/star-native/bsd/dev/star/*.h 2>/dev/null | head
echo "===== 我的新函数区（3745-3800）====="
sed -n '3745,3800p' "$F"
