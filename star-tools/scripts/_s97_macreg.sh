#!/bin/bash
K=/root/star26/star-native/bsd/kern/kern_minimac.c
OUT=/mnt/c/ios26/s97_macreg.out
: > "$OUT"

echo "=== 1) miniamfi_conf MAC policy registration ===" >> "$OUT"
grep -n -A18 'miniamfi_conf' "$K" | head -30 >> "$OUT"

echo "" >> "$OUT"
echo "=== 2) where mac_policy_register is called / is minimac_policy_init reached? ===" >> "$OUT"
grep -rn 'minimac_policy_init' /root/star26/star-native/bsd /root/star26/star-native/osfmk 2>/dev/null | head -10 >> "$OUT"

echo "" >> "$OUT"
echo "=== 3) MAC framework: is vnode_check_signature enabled in release kernel? ===" >> "$OUT"
grep -rn 'MACF\|CONFIG_MACF' /root/star26/star-native/config/MASTER | head -10 >> "$OUT"

echo "" >> "$OUT"
echo "=== 4) in s96 kernel: is the hook symbol present? ===" >> "$OUT"
NM=/root/star-build/xnu-deps/host/bin/nm
U=/root/star26/star-native/BUILD/obj/RELEASE_ARM64_BCM2837/mach.release.bcm2837.unstripped.noctf
"$NM" "$U" 2>/dev/null | grep -iE '_miniamfi_vnode_check_signature|_star_cs_valid' | head >> "$OUT"
echo "(end)" >> "$OUT"

echo "" >> "$OUT"
echo "=== DONE ===" >> "$OUT"
echo "OK $(wc -c < "$OUT") bytes"
