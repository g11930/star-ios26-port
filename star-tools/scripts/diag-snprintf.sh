#!/bin/bash
T=/root/star26/star-native
B=$T/BUILD/obj/RELEASE_ARM64_BCM2837
N=/root/star-build/xnu-deps/host/bin/nm

echo "=== CONFIG_VSPRINTF in the bsd Makefile ==="
grep -o 'DCONFIG_VSPRINTF' "$B/bsd/RELEASE/Makefile" | head -2
echo "(no line above means NOT defined)"

echo "=== files mentioning CONFIG_VSPRINTF ==="
grep -rln 'CONFIG_VSPRINTF' "$T/libsa" "$T/osfmk" "$T/libkern" --include=*.c 2>/dev/null | head -10

echo "=== snprintf / vsnprintf bodies found by name ==="
grep -rn '^snprintf(\|^vsnprintf(\|^int *$' "$T/libsa" "$T/osfmk/device/subrs.c" --include=*.c 2>/dev/null | head -20

echo "=== definitions in the linked kernel ==="
$N "$B/mach.release.bcm2837" 2>/dev/null | grep -E ' _snprintf$| _vsnprintf$| _consume_printf_args$| _doprnt$' | head -10

echo "=== which object defines _snprintf ==="
for o in $(find "$B" -name '*.o' 2>/dev/null | grep -E 'subrs|printf|sprintf' | head -20); do
    line=$($N "$o" 2>/dev/null | grep -E ' T _snprintf$| T _vsnprintf$' | head -2)
    [ -n "$line" ] && echo "$o -> $line"
done
