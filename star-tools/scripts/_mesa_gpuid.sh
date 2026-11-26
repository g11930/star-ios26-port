#!/bin/bash
F=/root/star26/hackios-xnu-kernel/xnu-deps/build/mesa/mesa-26.2.5/src/freedreno/common/freedreno_devices.py
grep -n 'class GPUId' -A25 "$F" | head -40
echo "=== around 660 ==="
sed -n '615,630p' "$F"
</