#!/bin/bash
OUT=/mnt/c/ios26/patchA_cs.out
: > "$OUT"
C=/root/star26/star-native/bsd/kern/kern_cs.c
e() { echo "$@" >> "$OUT"; }

e "===== A) kern_cs.c 1-60 (includes + cs_debug decl) ====="
nl -ba "$C" | sed -n '1,60p' >> "$OUT"

e ""
e "===== B) kern_cs.c 170-320 (cs_debug parse + cs_allow_invalid + cs_invalid_page FULL) ====="
nl -ba "$C" | sed -n '170,320p' >> "$OUT"

e ""
e "===== C) IOLog precedent in kern_cs.c ====="
grep -n 'IOLog' "$C" | head -10 >> "$OUT"

e ""
e "===== D) proc_csflags_update / proc_csflags_clear availability ====="
grep -rn 'proc_csflags_set\|proc_csflags_clear' "$C" | head -10 >> "$OUT"

e ""
e "===== DONE ====="
echo "OK patchA_cs.out $(wc -c < "$OUT") bytes"
