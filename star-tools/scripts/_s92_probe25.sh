#!/bin/bash
# probe25 (read-only): FINAL. Establish the true CS_VALID loss point.
OUT=/mnt/c/ios26/probe25.out
R=/root/star26/star-native
L=/mnt/c/ios26

: > "$OUT"
e() { echo "$@" >> "$OUT"; }
sec() { e ""; e "############ $* ===================================="; }

sec "A) RUNTIME: error=22 / cs_flags across the WHOLE s-line (find the true regression)"
for f in "$L"/s8[0-9]-log.bin "$L"/s9[0-2]-log.bin "$L"/x-log.bin; do
  [ -f "$f" ] && e "  $(basename $f): err22=$(grep -a -c 'error=22' "$f") csflags=$(grep -a -c 'cs_flags=' "$f") AnnibaleMetal=$(grep -a -c 'AnnibaleMetal' "$f") reg_completed_1=$(grep -a -c 'registration completed device=1' "$f")"
done

sec "B) ubc_subr.c 5225-5300 (found_but_not_valid -- the stale-blob reuse path)"
sed -n '5225,5300p' "$R/bsd/kern/ubc_subr.c" >> "$OUT" 2>/dev/null

sec "C) csblob_invalidate_flags + csvnode_invalidate_flags ALL call sites"
grep -rn "csblob_invalidate_flags\|csvnode_invalidate_flags\|cs_vnode_invalidate" "$R/bsd" "$R/osfmk" 2>/dev/null | grep -v "\.o:" | head -30 >> "$OUT"

sec "D) kern_cs.c 495-520 (csblob_invalidate_flags body)"
sed -n '495,525p' "$R/bsd/kern/kern_cs.c" >> "$OUT" 2>/dev/null

sec "E) kern_proc.c 3770-3860 (proc_pidinfo CS ops + invalidated path)"
sed -n '3770,3860p' "$R/bsd/kern/kern_proc.c" >> "$OUT" 2>/dev/null

sec "F) who calls cs_invalid_page's clearing path: cs_process_invalidated"
grep -rn "cs_process_invalidated" "$R/bsd" "$R/osfmk" 2>/dev/null | grep -v "\.o:" | head -20 >> "$OUT"

sec "G) kern_cs.c 1040-1060 (the exact EINVAL gate) + its callers (csops)"
sed -n '1000,1075p' "$R/bsd/kern/kern_cs.c" >> "$OUT" 2>/dev/null
e "--- csops entry ---"
grep -rn "csops\b" "$R/bsd/kern/kern_cs.c" "$R/bsd/kern/kern_proc.c" 2>/dev/null | head -20 >> "$OUT"

sec "H) RUNTIME s91: what exactly happens right before the FIRST error=22 at line 4630"
f="$L/s91-log.bin"
[ -f "$f" ] && sed -n '4610,4632p' "$f" >> "$OUT"

sec "I) RUNTIME: which processes in s91 have ANY successful cs/entitlements read"
f="$L/s91-log.bin"
[ -f "$f" ] && { grep -a -i "entitlement" "$f" | head -20 >> "$OUT"; }

sec "J) mini_OSEntitlements + amfi table registration: is the amfi table actually registered?"
grep -n "amfi_register\|kern_amfi\|amfi_interface\|register_amfi" "$R/libkern/amfi/miniamfi.c" "$R/libkern/amfi/amfi.c" 2>/dev/null | head -20 >> "$OUT"
e "--- miniamfi.c tail (registration) ---"
tail -70 "$R/libkern/amfi/miniamfi.c" >> "$OUT" 2>/dev/null

sec "K) runtime: does the kernel ever print 'AMFI' / amfi registration?"
for n in 90 91; do
  f="$L/s$n-log.bin"
  [ -f "$f" ] && e "  s$n: $(grep -a -c -i 'amfi' "$f") amfi lines"
done

sec "L) kern_cs.c:1060-1110 (what the EINVAL gate guards -- entitlements)"
sed -n '1060,1115p' "$R/bsd/kern/kern_cs.c" >> "$OUT" 2>/dev/null

sec "DONE"
echo OK