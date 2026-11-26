#!/bin/bash
NM=/root/star-build/xnu-deps/host/bin/nm
O=/root/star26/star-native/BUILD/obj/RELEASE_ARM64_BCM2837/bsd/RELEASE/kern_cs.o
U=/root/star26/star-native/BUILD/obj/RELEASE_ARM64_BCM2837/mach.release.bcm2837.unstripped.noctf
echo "=== nm kern_cs.o: star_cs symbols ==="
"$NM" "$O" 2>&1 | grep -i star_cs || echo "(none)"
echo "=== nm kern_cs.o: cs_init / cs_invalid_page ==="
"$NM" "$O" 2>&1 | grep -iE 'cs_init|cs_invalid_page' || echo "(none)"
echo "=== nm unstripped kernel: star_cs symbols ==="
"$NM" "$U" 2>&1 | grep -i star_cs || echo "(none)"
echo "=== nm unstripped kernel: cs_invalid_page ==="
"$NM" "$U" 2>&1 | grep -iE 'cs_invalid_page|_cs_init' || echo "(none)"
echo "=== what symbols ARE near cs in kernel (count) ==="
"$NM" "$U" 2>&1 | grep -ciE 'cs_' || echo "nm failed"
