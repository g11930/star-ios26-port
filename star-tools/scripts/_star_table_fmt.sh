#!/bin/bash
S=/root/star26/star-native/bsd/dev/star/annibale_adreno.c
echo "===== star speeds[] 表结构与内容 (2315-2360) ====="
sed -n '2315,2360p' "$S"
echo
echo "===== star HFI 消息 id 定义 ====="
grep -n -E "HFI_GX_BW_PERF_VOTE|HFI_PERF_TABLE|HFI_BW_TABLE|#define HFI_" "$S" | head -20
echo
echo "===== star hfi_send 函数签名 ====="
grep -n -E "hfi_send|^.*bool hfi_send|static.*hfi_send" "$S" | head -10
echo
echo "===== K90 adreno8_speeds / adreno8_gx_hz 结构 ====="
grep -n -E "adreno8_speeds\[\]|struct.*adreno8_speed|adreno8_gx_hz|adreno8_gx_count" /root/ref2/annibale-kernel/xnu/files/bsd/dev/adreno8/adreno8.c | head -15
grep -n -E "adreno8_speeds\[\]|struct.*speed|\.bus|khz|gx_hz" /root/ref2/annibale-kernel/xnu/files/bsd/dev/adreno8/adreno8_private.h | head -15
