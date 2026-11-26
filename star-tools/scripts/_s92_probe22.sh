#!/bin/bash
# probe22 (read-only): find cs_blobs.h, the CS_SIGNED / CS_PLATFORM_BINARY origin,
# the star amfi implementation, and the correct s92 log filename.
OUT=/mnt/c/ios26/probe22.out
R=/root/star26/star-native
L=/mnt/c/ios26

: > "$OUT"
e() { echo "$@" >> "$OUT"; }
sec() { e ""; e "############ $* ===================================="; }

sec "A) locate cs_blobs.h and read the CS_* flag block"
find "$R" -name "cs_blobs.h" 2>/dev/null >> "$OUT"
CSH=$(find "$R" -name "cs_blobs.h" 2>/dev/null | head -1)
e "--- using: $CSH ---"
[ -n "$CSH" ] && grep -n "define CS_" "$CSH" >> "$OUT" 2>/dev/null

sec "B) CS_ALLOWED_MACHO exact definition"
[ -n "$CSH" ] && grep -n -A6 "CS_ALLOWED_MACHO" "$CSH" >> "$OUT" 2>/dev/null

sec "C) mac_vnode_check_signature implementation (who may OR CS_SIGNED/CS_PLATFORM_BINARY)"
grep -rn "mac_vnode_check_signature" "$R" 2>/dev/null | grep -v "\.o:" | head -30 >> "$OUT"

sec "D) security/mac_* : cs_flags mutations"
for d in "$R/security" "$R/libkern/amfi" "$R/bsd/kern/code_signing"; do
  [ -d "$d" ] && { e "--- $d ---"; grep -rn "cs_flags\s*|=\|cs_flags\s*=\|\*cs_flags" "$d" 2>/dev/null | head -30 >> "$OUT"; }
done

sec "E) the whole star amfi stub"
e "--- miniamfi.c ---"; sed -n '1,80p' "$R/libkern/amfi/miniamfi.c" >> "$OUT" 2>/dev/null
e "--- amfi.h ---"; sed -n '1,120p' "$R/libkern/libkern/amfi/amfi.h" >> "$OUT" 2>/dev/null

sec "F) search entire tree for CS_PLATFORM_BINARY usage"
grep -rn "CS_PLATFORM_BINARY" "$R" 2>/dev/null | grep -v "\.o:" | head -30 >> "$OUT"

sec "G) search entire tree for CS_SIGNED writes"
grep -rn "CS_SIGNED" "$R/bsd" "$R/osfmk" "$R/security" "$R/libkern" 2>/dev/null | grep -v "\.o:" | head -40 >> "$OUT"

sec "H) proc_getcsflags / proc_csflags_set definition"
grep -rn "proc_csflags_set\|proc_getcsflags" "$R/bsd/kern/kern_proc.c" "$R/bsd/kern/kern_cs.c" 2>/dev/null | head -20 >> "$OUT"

sec "I) kern_exec.c 9160-9195 (the CS_SIGNED|CS_VALID set site)"
sed -n '9160,9195p' "$R/bsd/kern/kern_exec.c" >> "$OUT" 2>/dev/null

sec "J) kern_exec.c 2265,2300 (ip_csflags composition)"
sed -n '2265,2300p' "$R/bsd/kern/kern_exec.c" >> "$OUT" 2>/dev/null

sec "K) ALL s92-related files in C:/ios26"
ls -la "$L" 2>/dev/null | grep -i "s92" >> "$OUT"
e "--- largest recent .bin/.txt ---"
ls -laS "$L"/*.bin "$L"/*.txt 2>/dev/null | head -12 >> "$OUT"

sec "L) RUNTIME: which binary is FIRST to emit error=22 in s91 vs s89/s90"
for n in 89 90 91; do
  f="$L/s$n-log.bin"
  [ -f "$f" ] && {
    e "--- s$n : first 3 error=22 lines ---"
    grep -a -n "error=22" "$f" | head -3 >> "$OUT"
    e "  total: $(grep -a -c 'error=22' "$f")"
  }
done

sec "M) RUNTIME: s91 SpringBoard lifecycle (pid 33) - when does it die?"
f="$L/s91-log.bin"
[ -f "$f" ] && {
  grep -a -n "SpringBoard\[33" "$f" | head -5 >> "$OUT"
  e "  ..."
  grep -a -n "SpringBoard\[33" "$f" | tail -8 >> "$OUT"
  e "--- P28EXIT lines ---"
  grep -a -n "P28EXIT" "$f" | head -20 >> "$OUT"
}

sec "N) RUNTIME: s91 chronological first 60 lines around 03:03:50-03:04:00"
f="$L/s91-log.bin"
[ -f "$f" ] && grep -a -n "03:03:5[0-9]\|03:04:0[0-9]" "$f" | head -40 >> "$OUT"

sec "DONE"
echo OK