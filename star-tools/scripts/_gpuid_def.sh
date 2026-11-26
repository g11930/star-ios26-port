#!/bin/bash
M=/root/star26/hackios-xnu-kernel/xnu-deps/build/mesa/mesa-26.2.5/src/freedreno
grep -rn 'class GPUId' $M /root/star26/hackios-xnu-kernel/xnu-deps/build/mesa/mesa-26.2.5/src 2>/dev/null | head -4
F=$(grep -rln 'class GPUId' /root/star26/hackios-xnu-kernel/xnu-deps/build/mesa/mesa-26.2.5/src 2>/dev/null | head -1)
echo "file: $F"
[ -n "$F" ] && grep -n 'class GPUId' -A30 "$F" | head -45
</