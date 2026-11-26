#!/bin/bash
strings -n 5 /mnt/c/ios26/live-ps.bin > /tmp/lp.txt
echo "=== watchdog / stalls ==="
grep -a -i -E 'watchdog|not responding|unresponsive|spindump|stall|hang' /tmp/lp.txt | tail -12
echo "=== annibale timing lines ==="
grep -a 'annibalemetal\|AnnibaleGPU\|annibale:' /tmp/lp.txt | tail -20
</>
