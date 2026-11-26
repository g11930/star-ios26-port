#!/bin/bash
F=/root/star26/hackios-xnu-kernel/xnu-deps/build/mesa/mesa-26.2.5/src/freedreno/common/freedreno_devices.py
grep -n '660\|Adreno 6' "$F" | head -20
</