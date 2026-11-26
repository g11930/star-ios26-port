#!/bin/bash
OUT=/mnt/c/ios26/s95_rootdir.out
: > "$OUT"
e(){ echo "$@" >> "$OUT"; }
B=/root/star26/hackios-xnu-userland/userland

e "=== 1) root/lib/ contents ==="
ls -la "$B/root/lib/" 2>/dev/null | head -40 >> "$OUT"

e ""
e "=== 2) libannibale-sb26.dylib anywhere in tree ==="
find /root/star26 -name 'libannibale-sb26.dylib*' -printf '%s  %TY-%Tm-%Td %TH:%TM  %p\n' 2>/dev/null | head -20 >> "$OUT"

e ""
e "=== 3) compare: apfs.py cat dylib from s94 ramdisk ==="
cd "$B/tools/apfs" && python3 apfs.py cat /root/star26/s94/parts/ramdisk /annibale/lib/libannibale-sb26.dylib 2>&1 | head -3 >> "$OUT"

e ""
e "=== 4) root/ tree top ==="
ls -la "$B/root/" 2>/dev/null | head -30 >> "$OUT"

e ""
e "=== DONE ==="
echo "OK $(wc -c < "$OUT") bytes"
