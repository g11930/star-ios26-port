#!/bin/bash
# Why does the checkpoint hand back "0 bytes" even though the format strings
# are present in the linked kernel?  Inspect the printf-family gating and the
# actual machine code of star_display_milestone / star_trace.
T=/root/star26/star-native
B=$T/BUILD/obj/RELEASE_ARM64_BCM2837
OBJ=$B/bsd/RELEASE
DIS=llvm-objdump

echo "=== printf.c around CONFIG_NO_PRINTF_STRINGS ==="
sed -n '188,225p' "$T/osfmk/kern/printf.c"

echo "=== systm.h / stdio decl gating ==="
grep -rn "NO_PRINTF_STRINGS" -A 12 "$T/bsd/sys/systm.h" "$T/bsd/sys/stdio.h" \
    "$T/libkern/libkern/OSBase.h" 2>/dev/null | head -50

echo "=== star_log implementation ==="
sed -n '44,80p' "$T/bsd/dev/star/star_display_handoff.c"

echo "=== disassembly: star_display_milestone ==="
$DIS -d --macho "$OBJ/star_display_handoff.o" 2>/dev/null \
    | grep -A 30 '<_star_display_milestone>:' | head -35

echo "=== disassembly: star_trace ==="
$DIS -d --macho "$OBJ/kern_exec.o" 2>/dev/null \
    | grep -A 45 '<_star_trace>:' | head -50

echo "=== undefined symbols of the two objects ==="
N=/root/star-build/xnu-deps/host/bin/nm
for f in star_display_handoff kern_exec; do
    echo "--- $f"
    $N -u "$OBJ/$f.o" 2>/dev/null | grep -E 'snprintf|vsnprintf|loader_log|star_gate|IOLog'
done
