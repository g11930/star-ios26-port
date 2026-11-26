#!/bin/bash
S=/root/star26/star-native/bsd/dev/star
K=/root/star26/k90ref/kernel/xnu/files/bsd/dev
echo "===== star 侧 context_drained / drain 相关 ====="
grep -rn "context_drained\|drained\|adreno8_context_drained" "$S" 2>/dev/null | head -10
echo
echo "===== K90 侧 context_drained 定义 ====="
grep -rn "adreno8_context_drained" "$K" 2>/dev/null | grep -v "\.o:" | head -10
echo
echo "===== star 侧 hfi_send 签名与返回 ====="
grep -n "hfi_send\|static bool\|^hfi_send" "$S/annibale_adreno.c" | head -20
