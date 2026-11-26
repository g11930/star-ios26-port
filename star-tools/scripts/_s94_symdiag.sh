#!/bin/bash
U=/root/star26/star-native/BUILD/obj/RELEASE_ARM64_BCM2837/mach.release.bcm2837.unstripped.noctf
O=/root/star26/star-native/BUILD/obj/RELEASE_ARM64_BCM2837/bsd/RELEASE/kern_cs.o
S93=/root/star26/s93/parts/kernel
echo "=== symbols in kern_cs.o: star_cs_keep_valid ==="
nm -a "$O" 2>/dev/null | grep -i star_cs || echo "(nm -a none)"
echo "=== symbols in unstripped kernel: cs_invalid_page / star_cs ==="
nm -a "$U" 2>/dev/null | grep -iE 'star_cs_keep_valid|cs_invalid_page' || echo "(none)"
echo "=== objdump kern_cs.o around star_cs_keep_valid reference ==="
llvm-objdump -d "$O" 2>/dev/null | grep -i -B2 -A2 'star_cs' | head -20 || objdump -d "$O" 2>/dev/null | grep -i -B2 -A2 'star_cs' | head -20
echo "=== THE KEY TEST: does cs_debug bootarg string exist as standalone in s93 vs current? ==="
echo -n "s93 '^cs_debug$': "; strings -a "$S93" | grep -cxE 'cs_debug'
echo -n "s93 '^cs_enforcement_disable$': "; strings -a "$S93" | grep -cxE 'cs_enforcement_disable'
echo -n "s93 '^star_cs_keep_valid$': "; strings -a "$S93" | grep -cxE 'star_cs_keep_valid'
echo "=== compare: s93 has kernel from a DIFFERENT build tree? check BUILD mtimes ==="
stat -c '%y %n' /root/star26/s93/parts/kernel "$U" "$O"
