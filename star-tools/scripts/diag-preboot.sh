#!/bin/bash
echo "=== K90 kernel: preboot ==="
grep -rn "preboot" /root/star26/kbuild/xnu-12377.121.6/bsd --include='*.c' --include='*.h' 2>/dev/null | grep -v "preboot_verbose" | head -25
echo "=== star-native: preboot ==="
grep -rn "preboot" /root/star26/star-native/bsd --include='*.c' --include='*.h' 2>/dev/null | head -25
echo "=== loader: preboot ==="
grep -rn "preboot" /root/star26/hackios-xnu-kernel/xnuloader/*.inc 2>/dev/null | head -20
