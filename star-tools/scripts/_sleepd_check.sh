#!/bin/bash
OUT=/mnt/c/ios26/sleepd_check.out
: > "$OUT"
e(){ echo "$@" >> "$OUT"; }
T=/root/star26/hackios-xnu-userland/tools/apfs

e "=== 1) s94 ramdisk: sleepd files ==="
cd "$T" || exit 1
python3 apfs.py tree /root/star26/s94/parts/ramdisk / 2>/dev/null | grep -i sleepd >> "$OUT"
echo "(end sleepd files)" >> "$OUT"

e ""
e "=== 2) s94 log: sleepd / HKSPSleepStore / 4099 ==="
grep -a -i "sleepd\|HKSPSleepStore\|sleepserver\|4099" /mnt/c/ios26/s94-live3.bin | tr -d '\0' | head -30 >> "$OUT"
echo "(end log)" >> "$OUT"

e ""
e "=== 3) star build.sh job list (around 140 equivalent) ==="
grep -n -B3 -A5 "com.apple.sleepd" /root/star26/hackios-xnu-userland/userland/build.sh /root/star26/hackios-xnu-userland/userland/mkjobs.py 2>/dev/null | head -30 >> "$OUT"

e ""
e "=== 4) K90 build.sh job list context 130-145 ==="
sed -n '130,145p' /root/star26/warsaw-ref/userland/build.sh >> "$OUT"

e ""
e "=== 5) K90 STATUS sleepd note full context ==="
grep -n -A3 -B3 -i "sleepd" /root/star26/warsaw-ref/docs/V37-STATUS.md /root/star26/warsaw-ref/docs/STATUS-2026-11-09.md 2>/dev/null | head -30 >> "$OUT"

e ""
e "=== DONE ==="
echo "OK $(wc -c < "$OUT") bytes"
