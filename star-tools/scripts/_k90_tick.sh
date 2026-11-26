#!/bin/bash
K=/root/star26/k90ref/kernel/xnu/files/bsd/dev/adreno8/adreno8_hfi.c
echo "===== 720..840 speed_tick full ====="
sed -n '720,840p' "$K"
