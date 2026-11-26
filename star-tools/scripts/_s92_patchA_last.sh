#!/bin/bash
OUT=/mnt/c/ios26/patchA_last.out
: > "$OUT"
U=/root/star26/star-native/bsd/kern/ubc_subr.c
K=/root/star26/star-native/bsd/kern/kern_minimac.c
e() { echo "$@" >> "$OUT"; }

e "===== A) ubc_subr.c 4040-4115 (why 4102 may be skipped) ====="
nl -ba "$U" | sed -n '4040,4115p' >> "$OUT"

e ""
e "===== B) minimac_policy_init location + body ====="
LN=$(grep -n 'minimac_policy_init' "$K" | tail -1 | cut -d: -f1)
e "minimac_policy_init last line = $LN"
S=$((LN-5)); [ $S -lt 1 ] && S=1; E=$((LN+40))
nl -ba "$K" | sed -n "${S},${E}p" >> "$OUT"

e ""
e "===== C) IOLog precedent in kern_minimac.c ====="
grep -n 'IOLog' "$K" | head -10 >> "$OUT"

e ""
e "===== D) build-star-native.sh content ====="
cat /mnt/d/桌面/star26-deps/scripts/build-star-native.sh >> "$OUT"

e ""
e "===== E) s92 part dir layout (for cmdline edit) ====="
ls -la /root/star26/s92/parts/ >> "$OUT"

e ""
e "===== F) how previous sNN payloads were assembled (mkpayload calls in scripts) ====="
grep -rln 'mkpayload\|reseal-loader-img' /mnt/d/桌面/star26-deps/scripts/*.sh 2>/dev/null | head -10 >> "$OUT"
e "--- newest build script with full payload chain ---"
for f in $(grep -rln 'mkpayload' /mnt/d/桌面/star26-deps/scripts/*.sh 2>/dev/null | tail -3); do e "### $f"; cat "$f" >> "$OUT"; done

e ""
e "===== DONE ====="
echo "OK patchA_last.out $(wc -c < "$OUT") bytes"
