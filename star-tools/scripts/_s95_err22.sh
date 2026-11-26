#!/bin/bash
P=/mnt/c/ios26/s95-live.bin
OUT=/mnt/c/ios26/s95_err22.out
: > "$OUT"

echo "=== 1) all error=22 lines with context ===" >> "$OUT"
python3 - "$P" <<'PY' >> "$OUT"
import sys,re
t=open(sys.argv[1],'rb').read().decode('utf-8','replace').replace('\0','')
lines=t.split('\n')
for i,l in enumerate(lines):
    if 'error=22' in l or 'cs_flags=26000000' in l or 'NOT_CODESIGNED' in l:
        print("--- line %d ---"%i)
        for j in range(max(0,i-2),min(len(lines),i+2)):
            print("   ",lines[j][:200])
PY

echo "" >> "$OUT"
echo "=== 2) MACT / continuation violation / S:26 ===" >> "$OUT"
grep -a -i "MACT\|continuation violation\|gID S:26\|cs_flags" "$P" | tr -d '\0' | head -40 >> "$OUT"

echo "" >> "$OUT"
echo "=== 3) compare: same markers in s94 (should be 0) ===" >> "$OUT"
for s in MACT "continuation violation" "gID S:26" "error=22"; do
  echo -n "  s94 '$s' = " >> "$OUT"; grep -ac "$s" /mnt/c/ios26/s94-live3.bin >> "$OUT"
done

echo "" >> "$OUT"
echo "=== DONE ===" >> "$OUT"
echo "OK $(wc -c < "$OUT") bytes"
