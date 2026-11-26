#!/bin/bash
P=/mnt/c/ios26/s96-live.bin
OUT=/mnt/c/ios26/s96_diag.out
: > "$OUT"

echo "=== 1) boot-args as seen by launchd (star_cs_valid present?) ===" >> "$OUT"
grep -a "boot-args = " "$P" | tr -d '\0' | head -2 >> "$OUT"

echo "" >> "$OUT"
echo "=== 2) first error=22 full context ===" >> "$OUT"
python3 - "$P" <<'PY' >> "$OUT"
import sys
t=open(sys.argv[1],'rb').read().decode('utf-8','replace').replace('\0','')
lines=t.split('\n')
for i,l in enumerate(lines):
    if 'error=22' in l:
        for j in range(max(0,i-3),min(len(lines),i+3)):
            print("   ",lines[j][:200])
        break
PY

echo "" >> "$OUT"
echo "=== 3) cs_flags values seen (any with CS_VALID bit=1?) ===" >> "$OUT"
grep -a -o "cs_flags=[0-9a-fx]*" "$P" | tr -d '\0' | sort | uniq -c >> "$OUT"

echo "" >> "$OUT"
echo "=== 4) any new IOLog from our patches? ===" >> "$OUT"
grep -a -i "star_cs\|S96\|star_kv" "$P" | tr -d '\0' | head -10 >> "$OUT"
echo "(end)" >> "$OUT"

echo "" >> "$OUT"
echo "=== DONE ===" >> "$OUT"
echo "OK $(wc -c < "$OUT") bytes"
