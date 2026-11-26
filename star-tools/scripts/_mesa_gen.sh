#!/bin/bash
B=/root/star26/hackios-xnu-kernel/xnu-deps/build
F=$(find $B -name 'freedreno_dev_info.c' -o -name 'freedreno_dev_info.c' 2>/dev/null | head -3)
echo "gen file: $F"
for f in $F; do
  echo "--- $f"
  grep -n '0x06000600\|0x06030500' "$f" | head -4
  grep -n -A2 '0x06000600' "$f" | head -12
done
echo "=== a660 name in gen ==="
grep -rn 'Adreno 660\|Adreno (TM) 660' $B --include=freedreno_dev_info.c 2>/dev/null | head -4
</