#!/bin/bash
# probe20 (read-only): nail down where cs_flags=0x26000000 comes from.
OUT=/mnt/c/ios26/probe20.out
R=/root/star26/star-native
L=/mnt/c/ios26

: > "$OUT"
e() { echo "$@" >> "$OUT"; }
sec() { e ""; e "############ $* ===================================="; }

sec "A) CONFIG_NO_PRINTF_STRINGS state"
for f in "$R"/SETUP/config/star-native.config "$R"/SETUP/config/XNU.config; do
  [ -f "$f" ] && { e "--- $f"; grep -n "PRINTF_STRINGS\|CONFIG_NO_PRINTF" "$f" >> "$OUT" 2>/dev/null; }
done
e "--- grep whole SETUP ---"
grep -rn "CONFIG_NO_PRINTF_STRINGS" "$R/SETUP" >> "$OUT" 2>/dev/null | head -20

sec "B) mach_loader.c: every write to result->csflags"
grep -n "csflags" "$R/bsd/kern/mach_loader.c" >> "$OUT" 2>/dev/null

sec "C) kern_cs.c: every use of cs_debug"
grep -n "cs_debug" "$R/bsd/kern/kern_cs.c" >> "$OUT" 2>/dev/null

sec "D) who calls cs_allow_invalid"
grep -rn "cs_allow_invalid" "$R/bsd" "$R/osfmk" 2>/dev/null | head -30 >> "$OUT"

sec "E) magic 0x26000000 / CS_PLATFORM_BINARY|CS_NO_UNTRUSTED_HELPERS|CS_SIGNED in source"
grep -rn "0x26000000\|0x4000000 | CS\|CS_PLATFORM_BINARY | CS_NO_UNTRUSTED_HELPERS" "$R/bsd" "$R/osfmk" "$R/libkern" 2>/dev/null | head -30 >> "$OUT"

sec "F) cs_process_global_enforcement definition"
grep -rn "cs_process_global_enforcement" "$R/bsd/kern/"*.c "$R/bsd/kern/"*.h "$R/bsd/sys/"*.h 2>/dev/null | head -20 >> "$OUT"

sec "G) miniamfi.c / amfi.c: any hardcoded csflag assignment"
grep -n "csb_flags\|csflags\|CS_VALID\|CS_SIGNED\|CS_PLATFORM" "$R/libkern/amfi/miniamfi.c" 2>/dev/null >> "$OUT"
e "--- amfi.c ---"
grep -n "csb_flags\|csflags\|CS_VALID\|CS_SIGNED\|CS_PLATFORM" "$R/libkern/amfi/amfi.c" 2>/dev/null | head -40 >> "$OUT"

sec "H) ubc_subr.c: all paths that return a blob WITHOUT CS_VALID"
grep -n "csb_flags *=" "$R/bsd/kern/ubc_subr.c" >> "$OUT" 2>/dev/null
e "--- context around 4085-4115 ---"
sed -n '4085,4115p' "$R/bsd/kern/ubc_subr.c" >> "$OUT" 2>/dev/null
e "--- context around 5655,5680 ---"
sed -n '5655,5680p' "$R/bsd/kern/ubc_subr.c" >> "$OUT" 2>/dev/null

sec "I) runtime: does any sNN log contain cs_allow_invalid / ptrace / CS_DEBUGGED"
for n in 89 90 91 92; do
  f="$L/log-s$n.txt"
  [ -f "$f" ] || f=$(ls -1 "$L"/log*s${n}*.txt 2>/dev/null | head -1)
  if [ -n "$f" ] && [ -f "$f" ]; then
    e "  s$n ($f): ptrace=$(grep -c -i 'ptrace' "$f") cs_allow=$(grep -c 'cs_allow_invalid' "$f") CS_DEBUGGED=$(grep -c 'CS_DEBUGGED' "$f") amfi=$(grep -c -i 'AMFI' "$f")"
  else
    e "  s$n: (log file not found)"
  fi
done
e "--- available logs in $L ---"
ls -la "$L" | grep -i "log\|dump" >> "$OUT" 2>/dev/null

sec "J) the exact backboardd cs_flags=0x26000000 line(s) from live logs"
for n in 91 92; do
  f=$(ls -1 "$L"/log*s${n}*.txt 2>/dev/null | head -1)
  [ -n "$f" ] && [ -f "$f" ] && { e "--- s$n ---"; grep -n "26000000\|cs_flags" "$f" | head -20 >> "$OUT"; }
done

sec "K) kern_exec.c: ip_csflags writes (order matters)"
grep -n "ip_csflags" "$R/bsd/kern/kern_exec.c" >> "$OUT" 2>/dev/null

sec "DONE"
e "probe20 complete"

echo OK