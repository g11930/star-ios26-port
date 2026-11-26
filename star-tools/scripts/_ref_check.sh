#!/bin/bash
echo "=== GPU / adreno files in the public star repo ==="
find /root/g11930-ref -iname '*adreno*' -o -iname '*gpu*' -o -iname '*redwood*' 2>/dev/null | grep -v '\.git/' | head -40
echo
echo "=== gpu boot-arg occurrences ==="
grep -rn 'boot_argn("gpu"' /root/g11930-ref --include=*.c --include=*.cpp --include=*.h 2>/dev/null | head -10
echo
echo "=== metal-enable tool ==="
find /root/g11930-ref -iname '*metal-enable*' -o -iname 'metal_enable*' 2>/dev/null | head
echo
echo "=== kernel tree roots ==="
ls /root/g11930-ref/xnu 2>/dev/null | head
echo "=== dts/star drv dir ==="
ls /root/g11930-ref/xnu/bsd/dev 2>/dev/null | head -30
