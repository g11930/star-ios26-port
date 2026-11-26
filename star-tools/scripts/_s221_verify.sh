#!/bin/bash
export PATH=/root/star-build/xnu-deps/host/bin:$PATH
K=/root/star26/star-native/BUILD/obj/RELEASE_ARM64_BCM2837/mach.release.bcm2837.unstripped
echo "=== nm: PAC functions (unstripped) ==="
nm "$K" 2>/dev/null | grep -iE 'pac_patch_page|pac_rewrite|pac_emu_instruction|pac_load_config|pac_patch_encode' | head -20
echo "=== diagnostic strings in linked kernel ==="
grep -a -o 'pac: rewrite gate OPEN' "$K" | head -3
grep -a -o 'pac_patch_delay' "$K" | head -2
grep -a -o 'pac_patch_budget' "$K" | head -2
grep -a -o 'pac_patch_burst' "$K" | head -2
grep -a -o 'pac: traps=' "$K" | head -2
echo "=== kernel md5 ==="
md5sum "$K"
