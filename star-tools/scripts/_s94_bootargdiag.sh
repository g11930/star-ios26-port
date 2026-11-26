#!/bin/bash
B=/root/star26/star-native/BUILD/obj/RELEASE_ARM64_BCM2837/mach.release.bcm2837.unstripped.noctf
S=/root/star26/star-native/bsd/kern/kern_cs.c
O=/root/star26/star-native/BUILD/obj/RELEASE_ARM64_BCM2837/bsd/RELEASE/kern_cs.o
echo "=== exact boot-arg strings in UNSTRIPPED kernel ==="
for s in '^cs_debug$' '^star_cs_keep_valid$' '^star_cs_probe$' '^cs_enforcement_panic$' '^cs_library_val_enable$'; do
  echo -n "$s : "; strings -a "$B" | grep -cxE "${s}"
done
echo "=== exact boot-arg strings in kern_cs.o ==="
for s in '^cs_debug$' '^star_cs_keep_valid$' '^cs_enforcement_panic$'; do
  echo -n "$s : "; strings -a "$O" | grep -cxE "${s}" || true
done
echo "=== source: context around our parse (line 180-192) ==="
sed -n '180,192p' "$S"
echo "=== source: is our parse inside any #if? show preprocessor guards 160-195 ==="
awk 'NR>=160 && NR<=195 {print NR": "$0}' "$S" | grep -E '#if|#else|#endif|PE_parse|star_cs'
echo "=== objdump cs_init: does it reference star_cs_keep_valid string? ==="
OBJDUMP=/root/star-build/xnu-deps/host/bin/llvm-objdump
[ -x "$OBJDUMP" ] || OBJDUMP=objdump
"$OBJDUMP" -d "$O" 2>/dev/null | grep -i -A3 -B3 'star_cs' | head -30 || echo "(objdump unavailable)"
echo "=== check: maybe patch string merged/prefixed in kernel ==="
strings -a "$B" | grep -i 'keep.valid\|keep_valid\|cskeep' | head
