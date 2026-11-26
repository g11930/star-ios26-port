#!/bin/bash
UN=/root/star26/star-native/BUILD/obj/RELEASE_ARM64_BCM2837/mach.release.bcm2837.unstripped.noctf
OD=$(command -v llvm-objdump || echo llvm-objdump)
echo "=== symbol table entries for annibale_tl ==="
$OD -t "$UN" 2>/dev/null | grep -i "annibale_tl" || echo "(none via -t)"
echo
echo "=== any IOLog in a function named annibale_tl? ==="
$OD -d "$UN" 2>/dev/null | awk '/<_annibale_tl>:/{f=1} f&&/^$/{f=0} f' | head -40
