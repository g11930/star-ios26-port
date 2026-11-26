#!/bin/bash
T=/root/star26/star-native
B=$T/BUILD/obj/RELEASE_ARM64_BCM2837
N=/root/star-build/xnu-deps/host/bin/nm

echo "=== object defining _snprintf / _vsnprintf ==="
find "$B" -name '*.o' -print0 2>/dev/null | xargs -0 -n 40 "$N" 2>/dev/null \
    | grep -E ' T _snprintf$| T _vsnprintf$' | head -10

echo "=== per-object (with filename) ==="
for o in $(find "$B" -name '*.o' 2>/dev/null | grep -E 'printf|subrs|libsa|gen' | head -60); do
    line=$($N "$o" 2>/dev/null | grep -E ' T _snprintf$| T _vsnprintf$' | head -2)
    [ -n "$line" ] && echo "$o :: $line"
done

echo "=== source definition candidates ==="
grep -rn '^snprintf($\|^vsnprintf($\|^int *$' "$T/libsa" --include=*.c 2>/dev/null | head -10
grep -rn 'snprintf(char\|vsnprintf(char' "$T" --include=*.c --include=*.h 2>/dev/null | grep -v BUILD | head -10
