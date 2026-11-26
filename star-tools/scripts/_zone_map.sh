#!/bin/bash
echo "=== zalloc.h 里 ZONE_ID 枚举顺序（数出 21/27/28 对应什么） ==="
L=$(grep -n "ZONE_ID_IPC_PORT," /root/star26/star-native/osfmk/kern/zalloc.h | head -1 | cut -d: -f1)
echo "start line=$L"
sed -n "$((L-8)),$((L+25))p" /root/star26/star-native/osfmk/kern/zalloc.h | cat -n
echo
echo "=== 直接从内核符号表读 zone 名字（若有） ==="
grep -n "ZONE_ID_SEMAPHORE\|ZONE_ID_TURNSTILE\|ZONE_ID_IPC_PORT" /root/star26/star-native/osfmk/kern/zalloc.h
