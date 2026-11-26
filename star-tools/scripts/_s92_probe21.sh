#!/bin/bash
# probe21 (read-only): pin the CS_SIGNED|CS_PLATFORM_BINARY|CS_NO_UNTRUSTED_HELPERS source,
# and re-run the runtime greps with the CORRECT log filenames (sNN-log.bin).
OUT=/mnt/c/ios26/probe21.out
R=/root/star26/star-native
L=/mnt/c/ios26

: > "$OUT"
e() { echo "$@" >> "$OUT"; }
sec() { e ""; e "############ $* ===================================="; }

sec "A) CS_ALLOWED_MACHO mask definition"
grep -rn "define CS_ALLOWED_MACHO" "$R/bsd/kern/" "$R/bsd/sys/" 2>/dev/null >> "$OUT"
e "--- full cs_blobs.h flag block ---"
sed -n '/CS_VALID/,/CS_ALLOWED_MACHO/p' "$R/bsd/sys/cs_blobs.h" 2>/dev/null | head -120 >> "$OUT"

sec "B) mach_loader.c: CS_SIGNED / CS_PLATFORM_BINARY / CS_NO_UNTRUSTED_HELPERS writes"
grep -n "CS_SIGNED\|CS_PLATFORM_BINARY\|CS_NO_UNTRUSTED_HELPERS\|CS_DEBUGGED\|CS_DEV_CODE" "$R/bsd/kern/mach_loader.c" >> "$OUT" 2>/dev/null

sec "C) kern_exec.c: CS_SIGNED / CS_PLATFORM_BINARY / CS_DEBUGGED writes"
grep -n "CS_SIGNED\|CS_PLATFORM_BINARY\|CS_NO_UNTRUSTED_HELPERS\|CS_DEBUGGED" "$R/bsd/kern/kern_exec.c" >> "$OUT" 2>/dev/null

sec "D) mach_loader.c 3920-3990 (the |= blob->csb_flags site + neighbours)"
sed -n '3920,3990p' "$R/bsd/kern/mach_loader.c" >> "$OUT" 2>/dev/null

sec "E) mach_loader.c 1320-1345 (the CS_NO_UNTRUSTED_HELPERS |= site)"
sed -n '1320,1345p' "$R/bsd/kern/mach_loader.c" >> "$OUT" 2>/dev/null

sec "F) ubc_subr.c 4020-4060 (which branch takes csb_flags=0)"
sed -n '4020,4060p' "$R/bsd/kern/ubc_subr.c" >> "$OUT" 2>/dev/null

sec "G) ubc_subr.c 5700,5730 (the .csb_flags = cs_flags site)"
sed -n '5700,5730p' "$R/bsd/kern/ubc_subr.c" >> "$OUT" 2>/dev/null

sec "H) shared-cache code path: does star use dyld_shared_cache cs_blob?"
grep -rn "shared_cache\|shsharedcache\|dyld_shared" "$R/bsd/kern/ubc_subr.c" 2>/dev/null | head -20 >> "$OUT"

sec "I) RUNTIME (correct filenames): CODE SIGNING / cs_allow_invalid / CS_DEBUGGED"
for n in 87 88 89 90 91; do
  f="$L/s$n-log.bin"
  [ -f "$f" ] && e "  s$n: CODE_SIGNING=$(grep -a -c 'CODE SIGNING' "$f") cs_allow=$(grep -a -c 'cs_allow_invalid' "$f") CS_DEBUGGED=$(grep -a -c 'CS_DEBUGGED' "$f") invalid_page=$(grep -a -c 'invalid_page' "$f") STARX=$(grep -a -c 'STARX' "$f")"
done
[ -f "$L/s92-log.txt" ] && e "  s92 (txt, $(stat -c%s "$L/s92-log.txt") B):" && cat -v "$L/s92-log.txt" | head -10 >> "$OUT"

sec "J) RUNTIME: the exact cs_flags=0x26000000 / error=22 lines, s89..s92"
for n in 89 90 91; do
  f="$L/s$n-log.bin"
  [ -f "$f" ] && { e "--- s$n ---"; grep -a -n "26000000" "$f" | head -8 >> "$OUT"; e "  (error=22 count: $(grep -a -c 'error=22' "$f"))"; e "  (NOT_CODESIGNED count: $(grep -a -c 'NOT_CODESIGNED' "$f"))"; }
done

sec "K) RUNTIME: what process names carry NOT_CODESIGNED / error=22"
for n in 90 91; do
  f="$L/s$n-log.bin"
  [ -f "$f" ] && { e "--- s$n ---"; grep -a -o "NOT_CODESIGNED[^ ]*\|error=22" "$f" | sort | uniq -c >> "$OUT"; e "  contextual lines:"; grep -a -n "error=22" "$f" | head -14 >> "$OUT"; }
done

sec "L) RUNTIME: StarDisk / loader banner to confirm which run, plus last lines"
for n in 90 91; do
  f="$L/s$n-log.bin"
  [ -f "$f" ] && { e "--- s$n banner+tail ---"; grep -a -n "StarDisk\|star-native\|annibale\|Backboard\|backboardd" "$f" | head -6 >> "$OUT"; }
done

sec "DONE"
echo OK