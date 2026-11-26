#!/bin/bash
F=/root/star26/hackios-xnu-kernel/xnu-deps/build/mesa/mesa-26.2.5/src/freedreno/common/freedreno_devices.py
grep -n '0x060600\|FD660\|Adreno 660\|GPUId(660)' "$F" | head -10
echo "=== a6xx name block ==="
sed -n '600,660p' "$F" | grep -n 'GPUId' | head -12
echo "=== search 660 entries with names ==="
grep -n 'name=".*660*' "$F" | head -10
</