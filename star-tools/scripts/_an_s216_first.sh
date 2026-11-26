#!/bin/bash
L=/mnt/d/ios26/now-071613.bin
echo "=== [1] our new speed lines ==="
grep -a -E "speeds, .*MHz; votes|the speed wanted|the GMU accepts" "$L" | head -10
echo
echo "=== [2] GPU kept / service ==="
grep -a -E "THE GPU STAYS ON|THE GPU IS NOT STARTED|AnnibaleGPU" "$L" | head -6
echo
echo "=== [3] panic / fault ==="
grep -a -c "panic(" "$L" | sed 's/^/  panic( count: /'
grep -a -E "KERNEL FAULT|FASTBOOT RECOVERY|Debugger message|SMMU.*fault|smmu.*fsr \(0x[^0]" "$L" | head -6
echo
echo "=== [4] stage lines near 17 (context) ==="
grep -a -n "adreno: 17:" "$L" | head -12
echo
echo "=== [5] wallclock / uptime feel ==="
grep -a -oE "^[0-9]{2}:[0-9]{2}:[0-9]{2}" "$L" | tail -3
