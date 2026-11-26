#!/bin/bash
OUT=/mnt/c/ios26/s93_verify.out
: > "$OUT"
e() { echo "$@" >> "$OUT"; }
B=/root/star26/s93/s93-boot.img
K=/root/star26/s93/parts/kernel
P=/root/star26/s93/s93-payload.bin
KERN=/root/star26/hackios-xnu-kernel

e "=== 1) star_kv IOLog string in raw built kernel? ==="
strings -a /root/star26/star-native/BUILD/obj/RELEASE_ARM64_BCM2837/mach.release.bcm2837 | grep -i 'star_kv\|KEEP CS_VALID' | head >> "$OUT" 2>&1 || echo "(none)" >> "$OUT"
e "--- CONFIG_NO_PRINTF_STRINGS related: are OTHER IOLog strings present? ---"
strings -a "$KERN" | grep -c 'P28EXIT' >> "$OUT" 2>&1
strings -a /root/star26/star-native/BUILD/obj/RELEASE_ARM64_BCM2837/mach.release.bcm2837 | grep -c 'P28EXIT' >> "$OUT" 2>&1
e "--- star_cs_keep_valid occurrences ---"
strings -a "$KERN" | grep -c 'star_cs_keep_valid' >> "$OUT" 2>&1

e ""
e "=== 2) cmdline actually embedded in payload (extract near the string) ==="
strings -a "$P" | grep 'star_cs_keep_valid' >> "$OUT" 2>&1 | head -2

e ""
e "=== 3) boot.img container header sanity ==="
python3 -c "
d=open('$B','rb').read()
print('size', len(d))
print('has payload sha', __import__('hashlib').sha256(open('$P','rb').read()).hexdigest()[:16])
" >> "$OUT" 2>&1

e ""
e "=== 4) final deliverable md5/sha on both sides ==="
md5sum "$B" /mnt/c/ios26/s93-boot.img >> "$OUT" 2>&1
sha256sum "$B" /mnt/c/ios26/s93-boot.img >> "$OUT" 2>&1

e ""
e "=== DONE ==="
echo "OK s93_verify.out $(wc -c < "$OUT") bytes"
