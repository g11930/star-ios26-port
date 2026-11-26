#!/bin/bash
OUT=/mnt/c/ios26/s95_rootdir2.out
: > "$OUT"
e(){ echo "$@" >> "$OUT"; }
T=/root/star26/hackios-xnu-userland/tools/apfs

e "=== 1) cat dylib from s94 ramdisk -> file, md5 ==="
cd "$T" || exit 1
python3 apfs.py cat /root/star26/s94/parts/ramdisk /annibale/lib/libannibale-sb26.dylib > /mnt/c/ios26/s94-sb26.dylib 2>"$OUT.err"
md5sum /mnt/c/ios26/s94-sb26.dylib >> "$OUT" 2>&1
stat -c '%s bytes' /mnt/c/ios26/s94-sb26.dylib >> "$OUT" 2>&1
e "--- err (if any) ---"
cat "$OUT.err" >> "$OUT"

e ""
e "=== 2) find most-recent complete work/root trees (by dylib mtime) ==="
find /root/star26 -path '*/root/lib/libannibale-sb26.dylib' -printf '%TY-%Tm-%Td %TH:%TM  %p\n' 2>/dev/null | sort -r | head -12 >> "$OUT"

e ""
e "=== 3) s94 ramdisk build time vs work dirs ==="
stat -c '%y %n' /root/star26/s94/parts/ramdisk >> "$OUT"

e ""
e "=== 4) match: md5 of s94 dylib vs work copies ==="
S94=$(md5sum /mnt/c/ios26/s94-sb26.dylib 2>/dev/null | cut -d' ' -f1)
e "s94 dylib md5 = $S94"
for f in $(find /root/star26 -path '*/root/lib/libannibale-sb26.dylib' 2>/dev/null | head -30); do
  m=$(md5sum "$f" | cut -d' ' -f1)
  [ "$m" = "$S94" ] && e "  MATCH: $f"
done

e ""
e "=== DONE ==="
echo "OK $(wc -c < "$OUT") bytes"
