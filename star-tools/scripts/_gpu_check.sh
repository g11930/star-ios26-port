#!/bin/bash
echo "=== gpu boot-arg handling ==="
grep -rn 'boot_argn("gpu"' /root/star26/star-native --include=*.c --include=*.cpp --include=*.h 2>/dev/null | head -8
echo "=== adreno / redwood sources ==="
ls /root/star26/star-native/bsd/dev/ 2>/dev/null | grep -iE 'adreno|redwood|gpu|msm' | head -15
echo "=== staging bin ==="
ls -la /root/star26/s111/work/rootbuild/root/bin/ 2>/dev/null | grep -iE 'metal|redwood|gpu' | head -12
echo "=== staging lib ==="
ls -la /root/star26/s111/work/rootbuild/root/lib/ 2>/dev/null | grep -iE 'metal|redwood|annibale' | head -12
echo "=== staging bundle ==="
ls /root/star26/s111/work/rootbuild/root/lib/AnnibaleMetal.bundle 2>/dev/null | head
echo "=== rc.jobs ==="
cat /root/star26/s111/work/rootbuild/root/etc/rc.jobs 2>/dev/null | head -30
