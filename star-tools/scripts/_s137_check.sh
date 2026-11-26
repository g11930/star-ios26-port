#!/bin/bash
T=/tmp/s137d.txt
strings -n 5 /mnt/c/ios26/s137d-live.bin > $T
echo "=== who actually calls the kernel matcher ==="
grep -a 'IOSvcIn' $T | head -14
echo
echo "=== results seen by the shims ==="
grep -an 'say .*trace: .*IOServiceMatching\|no AnnibaleGPU service\|AnnibaleGPU client' $T | head -8
echo
echo "=== GPU still up? ==="
grep -ac 'THE GPU STAYS ON' $T
</bash>
