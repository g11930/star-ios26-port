#!/bin/bash
SDK=/root/star26/hackios-xnu-userland/userland/xnu-deps/26/sdk/iPhoneOS.sdk
AV="$SDK/usr/include/Availability.h"
echo "=== Availability.h __OSX_AVAILABLE_STARTING 定义上下文 ==="
grep -n '__OSX_AVAILABLE_STARTING\|__API_UNAVAILABLE\|#if 0\|#endif /\* 0' "$AV" | head -30
echo "=== 文件行数 ==="
wc -l "$AV"
echo "=== 前 60 行 ==="
sed -n '1,60p' "$AV"
