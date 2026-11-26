#!/bin/bash
L=/mnt/d/ios26/s216-mid-072141.bin
echo "=== [1] panic / fault ==="
printf '  panic( count: %s\n' "$(grep -a -c 'panic(' "$L")"
grep -a -E "KERNEL FAULT|FASTBOOT RECOVERY|Debugger message" "$L" | head -3
echo
echo "=== [2] GPU reports ==="
grep -a "AnnibaleGPU:" "$L" | grep -E "the GPU worked|submissions in|waits of|buffers:" | tail -8
echo
echo "=== [3] speed lines (should still be there, buffer rolls) ==="
grep -a -E "10 speeds, .*MHz|the speed wanted|GMU accepts the speed" "$L" | head -4
echo
echo "=== [4] render / springboard ==="
grep -a -c "render pipelines" "$L" | sed 's/^/  render pipelines lines: /'
grep -a -E "render pipelines|THE GPU STAYS" "$L" | tail -4
echo
echo "=== [5] wallclock ==="
grep -a -oE "^[0-9]{2}:[0-9]{2}:[0-9]{2}" "$L" | tail -1
echo
echo "=== [6] PAC traps (why 1fps) ==="
grep -a -c "^tl: c before" "$L" | sed 's/^/  trap lines: /'
