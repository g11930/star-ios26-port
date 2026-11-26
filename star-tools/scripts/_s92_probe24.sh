#!/bin/bash
# probe24 (read-only): final. Is CS_VALID never-set or silently-cleared?
# Plus: does star patch ubc_subr.c? Where does tmp_blob.csb_flags come from?
OUT=/mnt/c/ios26/probe24.out
R=/root/star26/star-native
L=/mnt/c/ios26

: > "$OUT"
e() { echo "$@" >> "$OUT"; }
sec() { e ""; e "############ $* ===================================="; }

sec "A) function boundaries in ubc_subr.c around 4000-4900"
grep -n "^[a-z_]*(\|^static .*(\|^ubc_cs_blob_add\|^cs_blob_init\|^cs_blob_create_validated" "$R/bsd/kern/ubc_subr.c" | awk -F: '$1>3950 && $1<5000' >> "$OUT" 2>/dev/null
e "--- grep function defs ---"
grep -n "cs_blob_create_validated\|^cs_blob_init_validated\|ubc_cs_blob_add\|cs_blob_init_validated(" "$R/bsd/kern/ubc_subr.c" >> "$OUT" 2>/dev/null

sec "B) ubc_subr.c 4700-4830 (what fills tmp_blob before the MAC hook)"
sed -n '4700,4830p' "$R/bsd/kern/ubc_subr.c" >> "$OUT" 2>/dev/null

sec "C) any star/Star/S9x patch markers in ubc_subr.c and kern_cs.c and kern_minimac.c"
grep -n "star\|Star\|STAR\|S9[0-9]\|hackios" "$R/bsd/kern/ubc_subr.c" "$R/bsd/kern/kern_cs.c" "$R/bsd/kern/kern_minimac.c" >> "$OUT" 2>/dev/null | head -40
e "(empty above = no star patch markers)"

sec "D) byte-diff kern_minimac.c against any backups"
ls -la "$R/bsd/kern/kern_minimac"* "$R/bsd/kern/kern_cs"*.bak "$R/bsd/kern/ubc_subr"*.bak 2>/dev/null >> "$OUT"
e "--- md5 of current + baks ---"
md5sum "$R/bsd/kern/kern_minimac.c" "$R/bsd/kern/ubc_subr.c" "$R/bsd/kern/kern_cs.c" "$R/bsd/kern/mach_loader.c" 2>/dev/null >> "$OUT"

sec "E) compare kern_minimac.c across s-line backups if any exist"
find "$R/bsd/kern" -name "kern_minimac*" 2>/dev/null >> "$OUT"
find "$R" -name "*.s9*.bak" -newermt "2026-11-16" 2>/dev/null | head -40 >> "$OUT"

sec "F) cs_invalid_page: is it armed? (verbose=cs_debug gating + callers)"
sed -n '249,315p' "$R/bsd/kern/kern_cs.c" >> "$OUT" 2>/dev/null

sec "G) RUNTIME s91: everything between metal registration and the FIRST error=22"
f="$L/s91-log.bin"
[ -f "$f" ] && sed -n '4600,4640p' "$f" >> "$OUT"

sec "H) RUNTIME s91: csops-ish / container / dyld / AMFI / trust cache lines"
f="$L/s91-log.bin"
[ -f "$f" ] && {
  e "--- AMFI ---";      grep -a -c -i "amfi" "$f" >> "$OUT"; grep -a -i "amfi" "$f" | head -6 >> "$OUT"
  e "--- dyld ---";      grep -a -c -i "dyld" "$f" >> "$OUT"
  e "--- trust cache ---"; grep -a -i "trust cache\|trustcache" "$f" | head -6 >> "$OUT"
  e "--- container ---"; grep -a -i "containermanagerd" "$f" | head -8 >> "$OUT"
  e "--- csops ---";     grep -a -i "csops\|cs_ops" "$f" | head -8 >> "$OUT"
  e "--- codesign ---";  grep -a -i "codesign\|code signing" "$f" | head -8 >> "$OUT"
  e "--- kernel task cs ---"; grep -a "kernel_task\|cs_blob" "$f" | head -6 >> "$OUT"
}

sec "I) RUNTIME s90 vs s91: total SecTaskLoadEntitlements invocations & outcomes"
for n in 89 90 91; do
  f="$L/s$n-log.bin"
  [ -f "$f" ] && e "  s$n: all=$(grep -a -c 'SecTaskLoadEntitlements' "$f")  ok=$(grep -a -c 'SecTaskLoadEntitlements' "$f")  err22=$(grep -a -c 'error=22' "$f")"
done
e "--- s90 all SecTaskLoadEntitlements-with-context lines ---"
grep -a "SecTaskLoadEntitlements" "$L/s90-log.bin" 2>/dev/null | head -10 >> "$OUT"
e "--- s89 all ---"
grep -a "SecTaskLoadEntitlements" "$L/s89-log.bin" 2>/dev/null | head -10 >> "$OUT"

sec "J) RUNTIME: does s90 have the AnnibaleMetal/MTLDevice lines at all? (regression boundary)"
for n in 88 89 90 91; do
  f="$L/s$n-log.bin"
  [ -f "$f" ] && e "  s$n: AnnibaleMetal=$(grep -a -c 'AnnibaleMetal' "$f") MTLDevice=$(grep -a -c 'MTLDevice' "$f") PearlEventFilter=$(grep -a -c 'PearlEventFilter' "$f") BiometricKit=$(grep -a -c 'BiometricKit' "$f")"
done

sec "K) RUNTIME: s91 - backboardd[39] death and what replaced it"
f="$L/s91-log.bin"
[ -f "$f" ] && {
  grep -a -n "backboardd\[39\]" "$f" | tail -5 >> "$OUT"
  e "--- 88s gap check: last line before and after ---"
  grep -a -n "acquired main display digitizer\|Creating connection to com.apple.runningboard" "$f" | head -10 >> "$OUT"
}

sec "DONE"
echo OK