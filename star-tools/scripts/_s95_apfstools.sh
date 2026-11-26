#!/bin/bash
OUT=/mnt/c/ios26/s95_apfstools.out
: > "$OUT"
e(){ echo "$@" >> "$OUT"; }
T=/root/star26/hackios-xnu-userland/tools/apfs

e "=== apfs tools available ==="
ls -la "$T" 2>/dev/null | head -40 >> "$OUT"

e ""
e "=== mkapfs.py usage ==="
head -50 "$T/mkapfs.py" 2>/dev/null >> "$OUT"

e ""
e "=== any extract/unpack tool ==="
find "$T" -type f \( -name '*extract*' -o -name '*unpack*' -o -name '*read*' \) -printf '%f\n' 2>/dev/null >> "$OUT"

e ""
e "=== how was s94 ramdisk built? check history for ROOT/annibale build ==="
grep -rn "rootV.apfs\|root\.apfs" /root/star26/s9*/parts/ 2>/dev/null | head -5 >> "$OUT"
e "--- s94 ramdisk first bytes (APFS magic) ---"
xxd -l 64 /root/star26/s94/parts/ramdisk 2>/dev/null >> "$OUT"

e ""
e "=== check-image / apfs_reader capabilities ==="
ls "$T"/*.py 2>/dev/null >> "$OUT"
grep -rn 'argparse\|add_argument' "$T/mkapfs.py" 2>/dev/null | head -20 >> "$OUT"

e ""
e "=== DONE ==="
echo "OK $(wc -c < "$OUT") bytes"
