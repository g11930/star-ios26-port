#!/bin/bash
SDK=/root/star26/hackios-xnu-userland/userland/xnu-deps/26/sdk/iPhoneOS.sdk
AV="$SDK/usr/include/os/availability.h"
echo "=== __API_UNAVAILABLE定义 ==="
grep -n 'define __API_UNAVAILABLE\|define __OSX_AVAILABLE_STARTING\|endif /\* 0 \*/\|endif /\* __has' "$AV" | head -20
echo "=== __OSX_AVAILABLE_STARTING 定义在哪个头 ==="
grep -rln 'define __OSX_AVAILABLE_STARTING' "$SDK/usr/include" 2>/dev/null | head -5
echo "=== availability.h 全文行数与 0 patch 位置 ==="
wc -l "$AV"
grep -n '/\* 0 \*/\|#if 0\|#if __has' "$AV" | head
