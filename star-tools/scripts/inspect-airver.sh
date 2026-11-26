#!/bin/bash
L=/root/star26/release/v0.1.3/hackios-k90-v0.1.3/root/lib/libannibaleair.dylib
B=/root/star-build/xnu-deps/build/mesa
echo "=== built-from-air ==="
cat "$B/out/built-from-air"; echo
echo "=== built-from ==="
cat "$B/out/built-from"; echo
echo "=== version strings in shipped air lib ==="
strings "$L" | grep -E "^(Mesa|mesa) [0-9]|^2[0-9]\.[0-9]\.[0-9]$|Mesa 2[0-9]" | head -10
echo "=== any 26.x marker ==="
strings "$L" | grep -c "26\.2\.5"
echo "=== mesa version symbol ==="
strings "$L" | grep -i "25\.0\.7\|26\.0\|26\.2" | head -10
echo "=== source tree patch stamp ==="
cat "$B/mesa-25.0.7/.annibale-patches" 2>/dev/null; echo
