#!/bin/bash
B=/root/star26/hackios-xnu-kernel/xnu-deps/build/mesa/mesa-26.2.5
F=$B/src/freedreno/common/freedreno_dev_info.c
echo "lines: $(wc -l < $F)"
grep -n 'FD660\|0x060600\|Adreno' $F | head -10
echo "=== generated header ==="
H=$B/src/freedreno/common/freedreno_dev_info.h
[ -f "$H" ] && grep -n 'FD660\|Adreno' "$H" | head -6
echo "=== python: how names applied ==="
grep -n 'name' $B/src/freedreno/common/freedreno_devices.py | sed -n '1,12p'
</