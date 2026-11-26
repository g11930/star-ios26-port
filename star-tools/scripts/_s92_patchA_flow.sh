#!/bin/bash
OUT=/mnt/c/ios26/patchA_flow.out
: > "$OUT"
U=/root/star26/star-native/bsd/kern/ubc_subr.c
M=/root/star26/star-native/bsd/kern/mach_loader.c
E=/root/star26/star-native/bsd/kern/kern_exec.c
e() { echo "$@" >> "$OUT"; }

e "===== A) ubc_subr.c 4840-4890 (first mac_vnode_check_signature call) ====="
nl -ba "$U" | sed -n '4840,4890p' >> "$OUT"

e ""
e "===== B) ubc_subr.c 5640-5730 (second call + cs_flags origin) ====="
nl -ba "$U" | sed -n '5640,5730p' >> "$OUT"

e ""
e "===== C) where does cs_flags local come from (grep in that function range) ====="
nl -ba "$U" | sed -n '5600,5710p' | grep -n 'cs_flags' >> "$OUT"

e ""
e "===== D) mach_loader.c result->csflags writes (all 6) ====="
grep -n 'result->csflags' "$M" >> "$OUT"

e ""
e "===== E) mach_loader.c around 3972 (the only OR-assign) ====="
nl -ba "$M" | sed -n '3950,3990p' >> "$OUT"

e ""
e "===== F) CS_VALID flow in exec: kern_exec.c 2265-2285 ====="
nl -ba "$E" | sed -n '2265,2285p' >> "$OUT"

e ""
e "===== G) cs_blob->csb_flags assignment sites in ubc_subr.c (the 2 setters) ====="
grep -n 'csb_flags.*CS_VALID\|csb_flags =' "$U" >> "$OUT"

e ""
e "===== H) blob extern linkage: is *cs_flags the same as csblob->csb_flags at 5703? ====="
nl -ba "$U" | sed -n '5695,5712p' >> "$OUT"

e ""
e "===== DONE ====="
echo "OK patchA_flow.out $(wc -c < "$OUT") bytes"
