#!/bin/bash
OUT=/mnt/c/ios26/s95_buildenv.out
: > "$OUT"
e(){ echo "$@" >> "$OUT"; }
B=/root/star26/hackios-xnu-userland/userland

e "=== 1) build.sh usage/flags ==="
sed -n '1,45p' "$B/build.sh" >> "$OUT"

e ""
e "=== 2) root/ dir current dylib ==="
ls -la "$B/root/annibale/lib/" 2>/dev/null | head -30 >> "$OUT"

e ""
e "=== 3) obj/ current dylib ==="
ls -la "$B/obj/"*.dylib 2>/dev/null | head -20 >> "$OUT"

e ""
e "=== 4) how build.sh copies obj dylib to root ==="
grep -n 'cp .*dylib\|annibale/lib\|COMPILE_ONLY\|SYSTEM=0\|DYLIB' "$B/build.sh" | head -30 >> "$OUT"

e ""
e "=== 5) root apfs generation section (930-950) ==="
sed -n '930,950p' "$B/build.sh" >> "$OUT"

e ""
e "=== 6) s94 ramdisk size vs root.apfs candidates ==="
find /root/star26/hackios-xnu-userland -name 'root*.apfs' -printf '%s  %TY-%Tm-%Td %TH:%TM  %p\n' 2>/dev/null | head >> "$OUT"

e ""
e "=== DONE ==="
echo "OK $(wc -c < "$OUT") bytes"
