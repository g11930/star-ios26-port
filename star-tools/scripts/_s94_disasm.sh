#!/bin/bash
U=/root/star26/star-native/BUILD/obj/RELEASE_ARM64_BCM2837/mach.release.bcm2837.unstripped.noctf
O=/root/star26/star-native/BUILD/obj/RELEASE_ARM64_BCM2837/bsd/RELEASE/kern_cs.o
TOOLS=/root/star-build/xnu-deps/host/bin
echo "=== available objdump/nm tools ==="
ls "$TOOLS" | grep -iE 'objdump|nm|readelf' | head
echo "=== objdump cs_init in kern_cs.o (localize) ==="
OD=$(ls "$TOOLS"/*objdump 2>/dev/null | head -1); [ -z "$OD" ] && OD=objdump
echo "using: $OD"
"$OD" -d "$O" 2>/dev/null | grep -A40 '<_cs_init>:' | head -45
echo "=== grep for star_cs_keep_valid address refs in cs_init via reloc ==="
"$OD" -r "$O" 2>/dev/null | grep -i -B2 -A2 'star_cs_keep_valid' | head -20
