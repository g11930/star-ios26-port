#!/bin/bash
M=/root/star26/hackios-xnu-kernel/xnu-deps/build/mesa/mesa-26.2.5/src/freedreno
grep -rn 'Adreno (TM) 660' $M 2>/dev/null | head -5
echo "=== a660 entries ==="
grep -rn 'a660' $M/common 2>/dev/null | head -8
echo "=== name format sites ==="
grep -rn 'name = ' $M/common/freedreno_devices.py 2>/dev/null | head -5
</