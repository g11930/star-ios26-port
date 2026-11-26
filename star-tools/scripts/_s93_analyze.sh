#!/bin/bash
OUT=/mnt/c/ios26/s93_staged_analysis.out
: > "$OUT"
e() { echo "$@" >> "$OUT"; }
P=/mnt/c/ios26/s93-staged.bin
e "=== size ==="
stat -c %s "$P" >> "$OUT"
e "=== full text (replace NUL) ==="
python3 - "$P" <<'PY' >> "$OUT"
import sys
d=open(sys.argv[1],'rb').read()
t=d.decode('utf-8','replace').replace('\0','')
print(t)
PY
e "=== END ==="
echo "OK $(wc -c < "$OUT") bytes"
