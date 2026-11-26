#!/bin/bash
L=/mnt/d/ios26/s217-mid-073704.bin
echo "=== degrees / sensors / tsens1 / GPU.clock ==="
grep -a -i "degrees\|sensors\|tsens\|clock is set" "$L" 2>/dev/null | tail -10
echo "=== gpu_kept marker (minute only runs when kept) ==="
grep -a -c "the GPU's sensors" "$L" 2>/dev/null
echo "=== any 'annibale: minute' or 60s lines ==="
grep -a -i "minute\|memory" "$L" 2>/dev/null | grep -i "GPU\|adreno\|sensor" | tail -5
