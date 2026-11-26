#!/bin/bash
OUT=/mnt/c/ios26/rb_diag2.out
: > "$OUT"
e(){ echo "$@" >> "$OUT"; }
L=/mnt/c/ios26/s94-live3.bin

e "=== 1) runningboardd Received handshake / connection from pid 32? ==="
grep -a "runningboardd\[" "$L" | tr -d '\0' | grep -iE "Received handshake|from 32|pid 32|SpringBoard|client.*32|osservice.*SpringBoard" | head -30 >> "$OUT"
echo "(end)" >> "$OUT"

e ""
e "=== 2) ALL 'Received handshake request' lines ==="
grep -a "Received handshake request" "$L" | tr -d '\0' >> "$OUT"

e ""
e "=== 3) ALL 'Handshake succeeded' lines ==="
grep -a "Handshake succeeded" "$L" | tr -d '\0' >> "$OUT"

e ""
e "=== 4) SpringBoard last 20 lines with full timestamp ==="
grep -a "SpringBoard\[32" "$L" | tr -d '\0' | tail -20 >> "$OUT"

e ""
e "=== 5) what happens in log right AFTER 03:03:54.731 (SpringBoard last line) ==="
python3 - "$L" <<'PY' >> "$OUT"
import sys
t=open(sys.argv[1],'rb').read().decode('utf-8','replace').replace('\0','')
lines=t.split('\n')
# find index of FBSystemShellInitialize
idx=None
for i,l in enumerate(lines):
    if 'FBSystemShellInitialize' in l: idx=i; break
print("FBSystemShellInitialize at line",idx)
if idx:
    for l in lines[idx:idx+30]: print("  ",l[:190])
PY

e ""
e "=== 6) K90 v37: does runningboard log handshake from SpringBoard? ==="
K=/root/star26/warsaw-ref/docs/v37/log-tail.txt
grep -a -i "Received handshake\|Handshake succeeded\|SpringBoard.*runningboard\|runningboard.*32" "$K" 2>/dev/null | head -20 >> "$OUT"
echo "(end)" >> "$OUT"

e ""
e "=== DONE ==="
echo "OK $(wc -c < "$OUT") bytes"
