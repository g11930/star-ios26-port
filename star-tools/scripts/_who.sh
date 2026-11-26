#!/bin/bash
echo "=== who prints 'trace: ... IOServiceMatching' ==="
grep -rn 'IOServiceMatching' /root/star26/hackios-xnu-userland /root/star26/hackios-xnu-kernel/tools 2>/dev/null | grep -v Binary | head -12
echo
echo "=== and who prints the 'no AnnibaleGPU service' ==="
grep -rn 'no AnnibaleGPU service' /root/star26/hackios-xnu-kernel/tools 2>/dev/null | head -3
</bash>
