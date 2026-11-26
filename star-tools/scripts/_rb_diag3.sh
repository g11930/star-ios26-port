#!/bin/bash
OUT=/mnt/c/ios26/rb_diag3.out
: > "$OUT"
e(){ echo "$@" >> "$OUT"; }
L=/mnt/c/ios26/s94-live3.bin

e "=== 1) Is there a K90 SpringBoard log with FBSystemShellInitialize? ==="
grep -rln "FBSystemShellInitialize" /root/star26/warsaw-ref/docs/ 2>/dev/null >> "$OUT"
echo "(end)" >> "$OUT"

e ""
e "=== 2) K90 v37 SpringBoard lines around startup (first 40) ==="
K=/root/star26/warsaw-ref/docs/v37/log-tail.txt
grep -a "SpringBoard\[" "$K" 2>/dev/null | head -40 >> "$OUT"

e ""
e "=== 3) s94: count of SpringBoard lines per minute (where it goes silent) ==="
python3 - "$L" <<'PY' >> "$OUT"
import re,collections
t=open(sys.argv[1],'rb').read().decode('utf-8','replace').replace('\0','')
c=collections.Counter()
for m in re.finditer(r'(\d{4}-\d\d-\d\d \d\d:\d\d):\d\d[^\n]*SpringBoard\[',t):
    c[m.group(1)]+=1
for k in sorted(c): print("  %s : %d SpringBoard lines"%(k,c[k]))
PY

e ""
e "=== 4) s94: what did SpringBoard do BEFORE 03:03:54 (startup milestones) ==="
grep -a "SpringBoard\[32" "$L" | tr -d '\0' | head -20 >> "$OUT"

e ""
e "=== 5) compare s90: same SpringBoard FBSystemShellInitialize + what followed ==="
S=/mnt/c/ios26/s90-live.bin
grep -a "SpringBoard\[" "$S" | tr -d '\0' | grep -iE "FBSystem|assertion|handshake|didFinish|launch|display" | head -20 >> "$OUT"

e ""
e "=== DONE ==="
echo "OK $(wc -c < "$OUT") bytes"
