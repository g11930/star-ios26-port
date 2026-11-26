#!/bin/bash
# If the s21 staged log is STILL 0 bytes, these facts decide the next move.
R=/root/star26/star-native
O=$R/BUILD/obj/RELEASE_ARM64_BCM2837
NM=/root/star-build/xnu-deps/host/bin/nm
echo "=== every reference to loader_log_len outside loader_return.c"
grep -rnF 'loader_log_len' "$R" --include='*.c' --include='*.h' --include='*.s' | grep -v 'loader_return.c' | head -30
echo "=== objects defining _vsnprintf"
find "$O" -name '*.o' -print0 | xargs -0 "$NM" -A 2>/dev/null | grep -F ' T _vsnprintf' | head -10
echo "=== objects defining _loader_log_len"
find "$O" -name '*.o' -print0 | xargs -0 "$NM" -A 2>/dev/null | grep -F '_loader_log_len' | head -15
echo "=== symbols around loader_log in the unstripped kernel"
"$NM" -n "$O/mach.release.bcm2837.unstripped" 2>/dev/null | grep -F -e ' _loader_log' -e ' _loader_live' | head -20
echo "=== DONE"
