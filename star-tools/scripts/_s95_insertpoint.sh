#!/bin/bash
OUT=/mnt/c/ios26/s95_insertpoint.out
: > "$OUT"
e(){ echo "$@" >> "$OUT"; }
K=/root/star26/warsaw-ref/userland/src/inject_sb26.c
S=/root/star26/hackios-xnu-userland/userland/src/inject/inject_sb26.c

e "=== K90 includes (1-40) ==="
sed -n '1,40p' "$K" >> "$OUT"
e ""
e "=== star lines 600-620 (CFBundle hook end) ==="
sed -n '600,620p' "$S" >> "$OUT"
e ""
e "=== star lines 760-778 (interpose table) ==="
sed -n '760,778p' "$S" >> "$OUT"
e ""
e "=== xpc.h in SDK? ==="
find /root/star-build/xnu-deps/sdk -path '*xpc/xpc.h' 2>/dev/null | head -3 >> "$OUT"
echo "(search done)" >> "$OUT"
e ""
e "=== pthread.h / time.h reachable ==="
find /root/star-build/xnu-deps/sdk -path '*usr/include/pthread.h' -o -path '*usr/include/time.h' 2>/dev/null | head -4 >> "$OUT"
e ""
e "=== star build: -fblocks present? ==="
grep -n 'fblocks\| Blocks\|DYN=' /root/star26/hackios-xnu-userland/userland/build.sh | head -10 >> "$OUT"
e ""
e "=== DONE ==="
echo "OK $(wc -c < "$OUT") bytes"
