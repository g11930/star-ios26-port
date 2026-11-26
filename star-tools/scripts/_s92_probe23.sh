#!/bin/bash
# probe23 (read-only): kern_minimac.c is the smoking gun. Read it whole, plus the
# ubc_subr.c call sites that pass cs_flags in/out.
OUT=/mnt/c/ios26/probe23.out
R=/root/star26/star-native

: > "$OUT"
e() { echo "$@" >> "$OUT"; }
sec() { e ""; e "############ $* ===================================="; }

sec "A) kern_minimac.c FULL"
wc -l "$R/bsd/kern/kern_minimac.c" >> "$OUT" 2>/dev/null
sed -n '1,140p' "$R/bsd/kern/kern_minimac.c" >> "$OUT" 2>/dev/null

sec "B) ubc_subr.c 4830-4960 (cs_blob init -> mac_vnode_check_signature -> tmp_blob)"
sed -n '4830,4960p' "$R/bsd/kern/ubc_subr.c" >> "$OUT" 2>/dev/null

sec "C) ubc_subr.c 5630-5720 (revalidate path, cs_flags lifecycle)"
sed -n '5630,5720p' "$R/bsd/kern/ubc_subr.c" >> "$OUT" 2>/dev/null

sec "D) mac_vfs.c:1316-1360 (the hook wrapper - what it does with cs_flags)"
sed -n '1310,1365p' "$R/security/mac_vfs.c" >> "$OUT" 2>/dev/null

sec "E) is kern_minimac.c in the build?"
grep -rn "kern_minimac" "$R/bsd/conf/"* "$R/bsd/kern/Makefile"* 2>/dev/null | head -20 >> "$OUT"
e "--- files list ---"
grep -rn "kern_minimac" "$R/bsd/kern/" 2>/dev/null | head -10 >> "$OUT"
e "--- obj present? ---"
ls -la "$R/BUILD/obj/RELEASE_ARM64_T8030/bsd/kern/kern_minimac.o" 2>/dev/null >> "$OUT"
find "$R/BUILD" -name "kern_minimac*" 2>/dev/null | head -5 >> "$OUT"
e "--- symbol in the s92 kernel image ---"
for n in 91 92; do
  f=$(ls -la /root/star26/s$n/ 2>/dev/null | head -20)
  e "--- s$n dir ---"; echo "$f" >> "$OUT"
done

sec "F) locates the built kernel binaries"
ls -la /root/star26/*/kernel* /root/star26/s9*/  2>/dev/null | head -40 >> "$OUT"

sec "G) runtime: confirm SpringBoard[33] error=22 is the FIRST, and its cs_flags"
f=/mnt/c/ios26/s91-log.bin
[ -f "$f" ] && {
  e "--- all distinct cs_flags values in s91 ---"
  grep -a -o "cs_flags=[0-9a-f]*" "$f" | sort | uniq -c >> "$OUT"
  e "--- lines 4620-4640 verbatim ---"
  sed -n '4620,4640p' "$f" >> "$OUT"
}

sec "H) runtime: s90 has ZERO error=22 - so what IS backboardd[39] cs_flags there?"
f=/mnt/c/ios26/s90-log.bin
[ -f "$f" ] && {
  e "--- any cs_flags at all in s90? ---"
  grep -a -o "cs_flags=[0-9a-f]*" "$f" | sort | uniq -c >> "$OUT"
  e "--- any SecTaskLoadEntitlements ---"
  grep -a -c "SecTaskLoadEntitlements" "$f" >> "$OUT"
  grep -a "SecTaskLoadEntitlements" "$f" | head -10 >> "$OUT"
}

sec "I) sbmetal26 registration lines s90 vs s91 (the A/B pivot)"
for n in 90 91; do
  f=/mnt/c/ios26/s$n-log.bin
  [ -f "$f" ] && { e "--- s$n ---"; grep -a -n "sbmetal26" "$f" | head -20 >> "$OUT"; }
done

sec "DONE"
echo OK