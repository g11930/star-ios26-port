#!/bin/bash
F=/root/star26/hackios-xnu-kernel/xnu-deps/build/mesa/mesa-26.2.5/src/freedreno/common/freedreno_dev_info.c
grep -n 'Adreno 660' "$F" | head -6
echo "=== chip ids containing 0600 ==="
grep -n '0x0600' "$F" | head -10
echo "=== size ==="
wc -l "$F"
</