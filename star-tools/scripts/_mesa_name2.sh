#!/bin/bash
M=/root/star26/hackios-xnu-kernel/xnu-deps/build/mesa/mesa-26.2.5
grep -rn 'Adreno 7c' $M --include=*.c --include=*.h --include=*.py 2>/dev/null | head -5
echo "=== 660 ==="
grep -rn '"Adreno 660"\|Adreno (TM) 660\|"a660"' $M --include=*.h --include=*.c 2>/dev/null | head -8
echo "=== devinfo names ==="
grep -rn 'name = "' $M/src/freedreno/common/freedreno_devices.py 2>/dev/null | head -4
